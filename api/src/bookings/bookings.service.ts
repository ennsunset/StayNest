// src/bookings/bookings.service.ts

import {
  Injectable, ConflictException, NotFoundException,
  ForbiddenException, BadRequestException, Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, LessThan } from 'typeorm';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Booking, BookingStatus } from './entities/booking.entity';
import { InstallmentPlan, Installment } from './entities/installment.entity';
import { Bed, BedStatus } from '../hostels/entities/hostel.entity';
import { NotificationsService } from '../notifications/notifications.service';

/** Hold duration in minutes */
const HOLD_MINUTES = 15;

/** Platform fee: 5% of room price */
const PLATFORM_FEE_RATE = 0.05;

@Injectable()
export class BookingsService {
  private readonly logger = new Logger(BookingsService.name);

  constructor(
    @InjectRepository(Booking) private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Bed) private readonly bedRepo: Repository<Bed>,
    @InjectRepository(InstallmentPlan) private readonly planRepo: Repository<InstallmentPlan>,
    @InjectRepository(Installment) private readonly installmentRepo: Repository<Installment>,
    private readonly dataSource: DataSource,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ── Hold a bed ────────────────────────────────────

  /**
   * The core booking flow from §5 of the build plan:
   * 1. BEGIN TRANSACTION
   * 2. SELECT ... FROM beds WHERE id = ? FOR UPDATE  ← row lock
   * 3. IF bed.status != AVAILABLE → fail
   * 4. UPDATE bed SET status = HELD, held_until = now() + 15min
   * 5. INSERT booking (status = HELD)
   * 6. COMMIT
   */
  async holdBed(studentId: string, bedId: string, checkInDate?: string, duration: string = 'FULL_YEAR', paymentType: string = 'FULL'): Promise<Booking> {
    return await this.dataSource.transaction(async (manager) => {
      // 1. Opportunistic expiry — clear any stale holds on this bed
      await this.expireStaleHold(manager, bedId);

      // 2. Row lock on the bed
      const bed = await manager.query(
        `SELECT b.id, b.status, b.room_id, r.price_pesewas
         FROM beds b
         JOIN rooms r ON r.id = b.room_id
         WHERE b.id = $1
         FOR UPDATE`,
        [bedId],
      );

      if (!bed.length) {
        throw new NotFoundException('Bed not found');
      }

      const bedRow = bed[0];

      // 3. Check availability
      if (bedRow.status !== BedStatus.AVAILABLE) {
        throw new ConflictException({
          message: 'This bed is no longer available',
          bedStatus: bedRow.status,
        });
      }

      // 4. Validate duration against hostel booking_mode
      const mode = bedRow.booking_mode || 'FLEXIBLE';
      if (mode === 'YEAR_ONLY' && duration !== 'FULL_YEAR') {
        throw new ConflictException('This hostel only allows full-year bookings');
      }
      if (mode === 'SEMESTER_ONLY' && duration === 'FULL_YEAR') {
        throw new ConflictException('This hostel only allows semester bookings');
      }

      // 5. Compute price based on duration
      // price_pesewas = per-semester price (base unit)
      // full year = 2x semester
      const semesterPrice = parseInt(bedRow.price_pesewas, 10);
      let pricePesewas: number;
      if (duration === 'FULL_YEAR') {
        pricePesewas = semesterPrice * 2;
      } else {
        pricePesewas = semesterPrice;
      }
      const platformFeePesewas = Math.round(pricePesewas * PLATFORM_FEE_RATE);
      const totalPesewas = pricePesewas + platformFeePesewas;

      // 5. Set hold
      const heldUntil = new Date(Date.now() + HOLD_MINUTES * 60 * 1000);
      await manager.query(
        `UPDATE beds SET status = $1, held_until = $2, updated_at = NOW() WHERE id = $3`,
        [BedStatus.HELD, heldUntil.toISOString(), bedId],
      );

      // 6. Generate reference: STN-YYYYMMDD-XXXX
      const reference = this.generateReference();

      // 7. Insert booking
      const [booking] = await manager.query(
        `INSERT INTO bookings (student_id, bed_id, status, reference, price_pesewas, platform_fee_pesewas, total_pesewas, held_until, check_in_date, payment_type)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         RETURNING *`,
        [studentId, bedId, BookingStatus.HELD, reference, pricePesewas, platformFeePesewas, totalPesewas, heldUntil.toISOString(), checkInDate ?? null, paymentType],
      );

      return this.rowToBooking(booking);
    });
  }

  // ── Get booking ───────────────────────────────────

  async findById(id: string): Promise<Booking> {
    const booking = await this.bookingRepo.findOne({
      where: { id },
      relations: ['bed', 'bed.room', 'bed.room.floor', 'bed.room.floor.building', 'bed.room.floor.building.hostel'],
    });
    if (!booking) throw new NotFoundException('Booking not found');
    return booking;
  }

  async findByStudent(studentId: string): Promise<Booking[]> {
    return this.bookingRepo.find({
      where: { studentId },
      relations: ['bed', 'bed.room', 'bed.room.floor', 'bed.room.floor.building', 'bed.room.floor.building.hostel'],
      order: { createdAt: 'DESC' },
    });
  }

  async findByReference(reference: string): Promise<Booking> {
    const booking = await this.bookingRepo.findOne({
      where: { reference },
      relations: ['bed', 'bed.room', 'bed.room.floor', 'bed.room.floor.building', 'bed.room.floor.building.hostel'],
    });
    if (!booking) throw new NotFoundException('Booking not found');
    return booking;
  }

  // ── Cancel booking ────────────────────────────────


  async getAgreement(bookingId: string) {
    const isRef = bookingId.startsWith('STN-');
    const rows = await this.dataSource.query(
      `SELECT
        b.id, b.reference, b.check_in_date, b.duration, b.status, b.agreement_signed_at,
        b.price_pesewas, b.platform_fee_pesewas, b.total_pesewas,
        u.full_name AS student_name, u.email AS student_email,
        h.name AS hostel_name, h.address AS hostel_address,
        h.house_rules, h.semester_duration_months, h.grace_period_days,
        r.number AS room_number, r.type AS room_type,
        bed.label AS bed_label
      FROM bookings b
      JOIN users u ON u.id = b.student_id
      JOIN beds bed ON bed.id = b.bed_id
      JOIN rooms r ON r.id = bed.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE ${isRef ? 'b.reference' : 'b.id'} = $1`,
      [bookingId],
    );

    if (!rows.length) throw new NotFoundException('Booking not found');
    const r = rows[0];

    const checkIn = r.check_in_date ? new Date(r.check_in_date) : new Date();
    const months = r.semester_duration_months || 4;
    const grace = r.grace_period_days || 5;
    const duration = r.duration || 'SEMESTER_1';

    const totalMonths = duration === 'FULL_YEAR' ? months * 2 : months;
    const endDate = new Date(checkIn);
    endDate.setMonth(endDate.getMonth() + totalMonths);
    endDate.setDate(endDate.getDate() + grace);

    // If check-in is weekend, shift to Monday
    const day = checkIn.getDay();
    if (day === 0) checkIn.setDate(checkIn.getDate() + 1);
    if (day === 6) checkIn.setDate(checkIn.getDate() + 2);

    const fmt = (d: Date) => d.toLocaleDateString('en-GB', { month: 'short', day: 'numeric', year: 'numeric' });

    return {
      contractId: r.reference,
      studentName: r.student_name,
      hostelName: r.hostel_name,
      property: `Room ${r.room_number}, ${r.bed_label}, ${r.hostel_name}`,
      termStart: fmt(checkIn),
      termEnd: fmt(endDate),
      duration: duration,
      houseRules: r.house_rules || 'I agree to the House Rules, including visitor curfew and noise policies as set by the hostel management.',
      status: r.status,
      signedAt: r.agreement_signed_at || null,
    };
  }

  async getRoommates(bookingId: string) {
    const isRef = bookingId.startsWith('STN-');
    const rows = await this.dataSource.query(
      `SELECT u.id AS user_id, u.full_name, u.level, u.university, b2.status
       FROM bookings b1
       JOIN beds bed1 ON bed1.id = b1.bed_id
       JOIN beds bed2 ON bed2.room_id = bed1.room_id AND bed2.id != bed1.id
       JOIN bookings b2 ON b2.bed_id = bed2.id AND b2.status IN ('CONFIRMED', 'CHECKED_IN')
       JOIN users u ON u.id = b2.student_id
       WHERE ${isRef ? 'b1.reference' : 'b1.id'} = $1`,
      [bookingId],
    );
    return rows.map((r: any) => ({
      userId: r.user_id,
      name: r.full_name,
      level: r.level,
      university: r.university,
      checkedIn: r.status === 'CHECKED_IN',
    }));
  }

  async createMaintenance(bookingId: string, studentId: string, body: { title: string; description?: string; category?: string; priority?: string }) {
    const isRef = bookingId.startsWith('STN-');
    const [booking] = await this.dataSource.query(
      `SELECT b.id, bl.hostel_id FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bl ON bl.id = f.building_id
       WHERE ${isRef ? 'b.reference' : 'b.id'} = $1`,
      [bookingId],
    );
    if (!booking) throw new NotFoundException('Booking not found');

    const [request] = await this.dataSource.query(
      `INSERT INTO maintenance_requests (booking_id, student_id, hostel_id, title, description, category, priority)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [booking.id, studentId, booking.hostel_id, body.title, body.description || '', body.category || 'GENERAL', body.priority || 'MEDIUM'],
    );
    return request;
  }

  async getMaintenance(bookingId: string) {
    const isRef = bookingId.startsWith('STN-');
    return this.dataSource.query(
      `SELECT * FROM maintenance_requests WHERE booking_id = (
        SELECT id FROM bookings WHERE ${isRef ? 'reference' : 'id'} = $1
      ) ORDER BY created_at DESC`,
      [bookingId],
    );
  }

  async checkIn(bookingId: string) {
    const isRef = bookingId.startsWith('STN-');
    const [booking] = await this.dataSource.query(
      `SELECT id, status FROM bookings WHERE ${isRef ? 'reference' : 'id'} = $1`,
      [bookingId],
    );
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.status === 'CHECKED_IN') {
      return { message: 'Already checked in' };
    }
    if (booking.status !== 'CONFIRMED') {
      throw new BadRequestException('Booking must be CONFIRMED to check in');
    }
    await this.dataSource.query(
      `UPDATE bookings SET status = 'CHECKED_IN', updated_at = NOW() WHERE id = $1`,
      [booking.id],
    );
    return { message: 'Checked in successfully', bookingId: booking.id };
  }

  async signAgreement(bookingId: string) {
    const isRef = bookingId.startsWith('STN-');
    const [booking] = await this.dataSource.query(
      `SELECT id, agreement_signed_at FROM bookings WHERE ${isRef ? 'reference' : 'id'} = $1`,
      [bookingId],
    );
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.agreement_signed_at) {
      return { alreadySigned: true, signedAt: booking.agreement_signed_at };
    }
    const [updated] = await this.dataSource.query(
      `UPDATE bookings SET agreement_signed_at = NOW(), updated_at = NOW() WHERE id = $1 RETURNING agreement_signed_at`,
      [booking.id],
    );
    return { alreadySigned: false, signedAt: updated.agreement_signed_at };
  }

  async cancel(bookingId: string, studentId: string, reason?: string): Promise<Booking> {
    return await this.dataSource.transaction(async (manager) => {
      const [booking] = await manager.query(
        `SELECT * FROM bookings WHERE id = $1 FOR UPDATE`,
        [bookingId],
      );
      if (!booking) throw new NotFoundException('Booking not found');
      if (booking.student_id !== studentId) throw new ForbiddenException('Not your booking');

      const cancellableStatuses = [BookingStatus.HELD, BookingStatus.PENDING_PAYMENT, BookingStatus.CONFIRMED];
      if (!cancellableStatuses.includes(booking.status)) {
        throw new BadRequestException(`Cannot cancel a booking with status ${booking.status}`);
      }

      // Release the bed
      await manager.query(
        `UPDATE beds SET status = $1, held_until = NULL, updated_at = NOW() WHERE id = $2`,
        [BedStatus.AVAILABLE, booking.bed_id],
      );

      // Update booking
      const [updated] = await manager.query(
        `UPDATE bookings SET status = $1, cancel_reason = $2, held_until = NULL, updated_at = NOW()
         WHERE id = $3 RETURNING *`,
        [BookingStatus.CANCELLED, reason ?? null, bookingId],
      );

      const cancelled = this.rowToBooking(updated);

      // If booking was CONFIRMED (payment was made), create refund with 24-hour policy
      if (booking.status === BookingStatus.CONFIRMED) {
        const totalPesewas = parseInt(booking.total_pesewas, 10) || 0;
        if (totalPesewas > 0) {
          const confirmedAt = new Date(booking.updated_at || booking.created_at);
          const hoursSinceConfirm = (Date.now() - confirmedAt.getTime()) / (1000 * 60 * 60);

          let refundAmount = totalPesewas;
          let refundStatus = 'APPROVED';
          let refundReason = reason ?? 'Student cancelled';

          if (hoursSinceConfirm <= 24) {
            // Within 24 hours: full refund, auto-approved
            refundAmount = totalPesewas;
            refundStatus = 'APPROVED';
            refundReason = (reason ? reason + ' — ' : '') + 'Free cancellation (within 24 hours)';
          } else {
            // After 24 hours: 10% fee, needs owner approval
            const fee = Math.round(totalPesewas * 0.10);
            refundAmount = totalPesewas - fee;
            refundStatus = 'REQUESTED';
            refundReason = (reason ? reason + ' — ' : '') + 'Late cancellation (10% fee applied)';
          }

          await manager.query(
            `INSERT INTO refunds (id, booking_id, amount_pesewas, status, reason, created_at, updated_at, approved_at)
             VALUES (gen_random_uuid(), $1, $2, $3, $4, NOW(), NOW(), $5)
             ON CONFLICT (booking_id) DO NOTHING`,
            [bookingId, refundAmount, refundStatus, refundReason, hoursSinceConfirm <= 24 ? new Date() : null],
          );
        }
      }

      // Fire notification to student (non-blocking)
      this.notifyBookingEvent(bookingId, studentId, booking.bed_id, booking.reference, 'BOOKING_CANCELLED').catch((err) => console.error('NOTIFY ERROR:', err.message));

      return cancelled;
    });
  }

  // ── Confirm (called after payment) ────────────────

  async confirm(bookingId: string): Promise<Booking> {
    const result = await this.dataSource.transaction(async (manager) => {
      const [booking] = await manager.query(
        `SELECT * FROM bookings WHERE id = $1 FOR UPDATE`,
        [bookingId],
      );
      if (!booking) throw new NotFoundException('Booking not found');

      if (booking.status !== BookingStatus.HELD && booking.status !== BookingStatus.PENDING_PAYMENT) {
        throw new BadRequestException(`Cannot confirm a booking with status ${booking.status}`);
      }

      // Check if hold expired
      if (booking.held_until && new Date(booking.held_until) < new Date()) {
        // Expire it instead
        await this.expireBooking(manager, booking);
        throw new ConflictException('Hold expired before payment was confirmed');
      }

      // Update bed to BOOKED
      await manager.query(
        `UPDATE beds SET status = $1, held_until = NULL, updated_at = NOW() WHERE id = $2`,
        [BedStatus.BOOKED, booking.bed_id],
      );

      // Update booking to CONFIRMED
      const [updated] = await manager.query(
        `UPDATE bookings SET status = $1, held_until = NULL, updated_at = NOW()
         WHERE id = $2 RETURNING *`,
        [BookingStatus.CONFIRMED, bookingId],
      );

      const confirmed = this.rowToBooking(updated);

      // Fire notification to student (non-blocking)
      this.notifyBookingEvent(bookingId, booking.student_id, booking.bed_id, booking.reference, 'BOOKING_CONFIRMED').catch((err) => console.error('NOTIFY ERROR:', err.message));

      return confirmed;
    });

    // If installment booking, create the plan after transaction commits
    const [ptRow] = await this.dataSource.query(
      `SELECT payment_type FROM bookings WHERE id = $1`, [bookingId],
    );
    if (ptRow?.payment_type === 'INSTALLMENT') {
      this.createInstallmentPlan(bookingId).catch((err) =>
        this.logger.error(`Failed to create installment plan for ${bookingId}: ${err.message}`),
      );
    }

    // Seed move-in tasks and utility accounts
    this.seedMoveInTasks(bookingId).catch((err) =>
      this.logger.error(`Failed to seed move-in tasks for ${bookingId}: ${err.message}`),
    );
    this.seedUtilityAccounts(bookingId).catch((err) =>
      this.logger.error(`Failed to seed utility accounts for ${bookingId}: ${err.message}`),
    );

    return result;
  }

  // ── Get beds for a room (with opportunistic expiry) ──

  async getBedsForRoom(roomId: string): Promise<any[]> {
    // Opportunistic expiry: clear any stale holds in this room
    const staleBeds = await this.bedRepo.query(
      `SELECT b.id FROM beds b
       WHERE b.room_id = $1 AND b.status = 'HELD' AND b.held_until < NOW()`,
      [roomId],
    );

    for (const sb of staleBeds) {
      await this.dataSource.transaction(async (manager) => {
        await this.expireStaleHold(manager, sb.id);
      });
    }

    // Return fresh bed states
    return this.bedRepo.query(
      `SELECT b.id, b.label, b.status, b.room_id, b.held_until,
              r.type AS room_type, r.price_pesewas, r.number AS room_number
       FROM beds b
       JOIN rooms r ON r.id = b.room_id
       WHERE b.room_id = $1
       ORDER BY b.label ASC`,
      [roomId],
    );
  }

  // ── Hold expiry background job ────────────────────

  /**
   * Runs every minute. Finds HELD bookings past their deadline and expires them.
   * Belt: the opportunistic expiry on read is the suspenders.
   */
  @Cron(CronExpression.EVERY_MINUTE)
  async handleHoldExpiry(): Promise<void> {
    const now = new Date().toISOString();

    const expired = await this.bookingRepo.query(
      `SELECT id, bed_id FROM bookings WHERE status = 'HELD' AND held_until < $1`,
      [now],
    );

    if (expired.length === 0) return;

    this.logger.log(`Expiring ${expired.length} stale hold(s)`);

    for (const row of expired) {
      try {
        await this.dataSource.transaction(async (manager) => {
          // Re-check under lock
          const [booking] = await manager.query(
            `SELECT * FROM bookings WHERE id = $1 AND status = 'HELD' FOR UPDATE`,
            [row.id],
          );
          if (!booking) return;
          if (new Date(booking.held_until) >= new Date()) return; // no longer stale

          await this.expireBooking(manager, booking);
        });
      } catch (err) {
        this.logger.error(`Failed to expire booking ${row.id}: ${err.message}`);
      }
    }
  }

  // ── Private helpers ───────────────────────────────

  /**
   * Expire a single stale hold on a bed. Called opportunistically on read
   * AND by the cron job.
   */
  @Cron('0 6 * * *') // Daily at 6 AM
  async handleAutoCheckIn(): Promise<void> {
    const today = new Date().toISOString().split('T')[0];
    const rows = await this.dataSource.query(
      `UPDATE bookings SET status = 'CHECKED_IN', updated_at = NOW()
       WHERE status = 'CONFIRMED' AND check_in_date IS NOT NULL AND check_in_date::date <= $1
       RETURNING id, reference`,
      [today],
    );
    if (rows.length > 0) {
      this.logger.log(`Auto checked-in ${rows.length} booking(s): ${rows.map((r: any) => r.reference).join(', ')}`);
    }
  }

  private async expireStaleHold(manager: any, bedId: string): Promise<void> {
    const [heldBooking] = await manager.query(
      `SELECT id FROM bookings WHERE bed_id = $1 AND status = 'HELD' AND held_until < NOW()
       FOR UPDATE SKIP LOCKED`,
      [bedId],
    );
    if (!heldBooking) return;

    await manager.query(
      `UPDATE bookings SET status = $1, held_until = NULL, updated_at = NOW() WHERE id = $2`,
      [BookingStatus.EXPIRED, heldBooking.id],
    );
    await manager.query(
      `UPDATE beds SET status = $1, held_until = NULL, updated_at = NOW() WHERE id = $2`,
      [BedStatus.AVAILABLE, bedId],
    );
  }

  private async expireBooking(manager: any, booking: any): Promise<void> {
    await manager.query(
      `UPDATE bookings SET status = $1, held_until = NULL, updated_at = NOW() WHERE id = $2`,
      [BookingStatus.EXPIRED, booking.id],
    );
    await manager.query(
      `UPDATE beds SET status = $1, held_until = NULL, updated_at = NOW() WHERE id = $2`,
      [BedStatus.AVAILABLE, booking.bed_id],
    );
  }

  private async notifyBookingEvent(bookingId: string, studentId: string, bedId: string, reference: string, type: string): Promise<void> {
    // Get hostel name + student_id for the notification
    const [info] = await this.dataSource.query(
      `SELECT h.name as hostel_name, bk.student_id
       FROM bookings bk
       JOIN beds b ON b.id = bk.bed_id
       JOIN rooms r ON r.id = b.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bl ON bl.id = f.building_id
       JOIN hostels h ON h.id = bl.hostel_id
       WHERE bk.id = $1`, [bookingId],
    );
    const hostelName = info?.hostel_name ?? 'your hostel';
    const resolvedStudentId = studentId || info?.student_id;

    if (!resolvedStudentId) return;

    if (type === 'BOOKING_CONFIRMED') {
      await this.notificationsService.create({
        userId: resolvedStudentId,
        type: 'BOOKING_CONFIRMED',
        title: 'Booking Confirmed',
        body: `Your booking at ${hostelName} (${reference}) has been confirmed.`,
        data: { bookingId, reference },
      });
      // Notify owner
      const [ownerInfo] = await this.dataSource.query(
        `SELECT h.owner_id FROM beds b
         JOIN rooms r ON r.id = b.room_id
         JOIN floors f ON f.id = r.floor_id
         JOIN buildings bl ON bl.id = f.building_id
         JOIN hostels h ON h.id = bl.hostel_id
         WHERE b.id = $1`, [bedId],
      );
      if (ownerInfo?.owner_id) {
        await this.notificationsService.create({
          userId: ownerInfo.owner_id,
          type: 'BOOKING_REQUEST',
          title: 'New Booking',
          body: `A student has booked a bed at ${hostelName} (${reference}).`,
          data: { bookingId, reference },
        });
      }
    } else if (type === 'BOOKING_CANCELLED') {
      await this.notificationsService.create({
        userId: resolvedStudentId,
        type: 'BOOKING_CANCELLED',
        title: 'Booking Cancelled',
        body: `Your booking at ${hostelName} (${reference}) has been cancelled.`,
        data: { bookingId, reference },
      });
      // Notify owner
      const [ownerInfo2] = await this.dataSource.query(
        `SELECT h.owner_id FROM beds b
         JOIN rooms r ON r.id = b.room_id
         JOIN floors f ON f.id = r.floor_id
         JOIN buildings bl ON bl.id = f.building_id
         JOIN hostels h ON h.id = bl.hostel_id
         WHERE b.id = $1`, [bedId],
      );
      if (ownerInfo2?.owner_id) {
        await this.notificationsService.create({
          userId: ownerInfo2.owner_id,
          type: 'BOOKING_CANCELLED',
          title: 'Booking Cancelled',
          body: `A student cancelled their booking at ${hostelName} (${reference}).`,
          data: { bookingId, reference },
        });
      }
    }
  }

  // ── Installment eligibility ─────────────────────

  async checkInstallmentEligibility(studentId: string, hostelId: string): Promise<{ eligible: boolean; reason?: string }> {
    const [hostel] = await this.dataSource.query(
      `SELECT installments_enabled FROM hostels WHERE id = $1`,
      [hostelId],
    );
    if (!hostel || !hostel.installments_enabled) {
      return { eligible: false, reason: 'Hostel does not offer installment payments' };
    }

    const [result] = await this.dataSource.query(
      `SELECT COUNT(*)::int AS cnt FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       WHERE b.student_id = $1
         AND bld.hostel_id = $2
         AND b.status IN ('COMPLETED', 'CHECKED_IN')`,
      [studentId, hostelId],
    );

    if (result.cnt === 0) {
      return { eligible: false, reason: 'Installments available for returning residents only' };
    }

    return { eligible: true };
  }

  // ── Create installment plan ──

  async createInstallmentPlan(bookingId: string): Promise<{ plan: any; installments: any[] }> {
    const [booking] = await this.dataSource.query(
      `SELECT id, total_pesewas, check_in_date, student_id FROM bookings WHERE id = $1`,
      [bookingId],
    );
    if (!booking) throw new NotFoundException('Booking not found');

    const total = parseInt(booking.total_pesewas, 10);
    const half = Math.floor(total / 2);
    const remainder = total - half;

    const now = new Date();
    const checkIn = booking.check_in_date ? new Date(booking.check_in_date) : now;
    const dueDateTwo = new Date(checkIn);
    dueDateTwo.setMonth(dueDateTwo.getMonth() + 2);

    const [plan] = await this.dataSource.query(
      `INSERT INTO installment_plans (booking_id, total_pesewas, installment_count, status)
       VALUES ($1, $2, 2, 'ACTIVE') RETURNING *`,
      [bookingId, total],
    );

    const [inst1] = await this.dataSource.query(
      `INSERT INTO installments (plan_id, sequence, amount_pesewas, due_date, status, paid_at)
       VALUES ($1, 1, $2, $3, 'PAID', NOW()) RETURNING *`,
      [plan.id, half, now.toISOString().slice(0, 10)],
    );

    const [inst2] = await this.dataSource.query(
      `INSERT INTO installments (plan_id, sequence, amount_pesewas, due_date, status)
       VALUES ($1, 2, $2, $3, 'PENDING') RETURNING *`,
      [plan.id, remainder, dueDateTwo.toISOString().slice(0, 10)],
    );

    return { plan, installments: [inst1, inst2] };
  }

  // ── Get installment plan for a booking ──

  async getInstallmentPlan(bookingId: string): Promise<{ plan: any; installments: any[] } | null> {
    const [plan] = await this.dataSource.query(
      `SELECT * FROM installment_plans WHERE booking_id = $1`,
      [bookingId],
    );
    if (!plan) return null;

    const installments = await this.dataSource.query(
      `SELECT * FROM installments WHERE plan_id = $1 ORDER BY sequence`,
      [plan.id],
    );
    return { plan, installments };
  }

  // ── Pay an installment ──

  async payInstallment(installmentId: string, paymentReference: string): Promise<any> {
    const [inst] = await this.dataSource.query(
      `SELECT i.*, ip.booking_id FROM installments i
       JOIN installment_plans ip ON ip.id = i.plan_id
       WHERE i.id = $1`,
      [installmentId],
    );
    if (!inst) throw new NotFoundException('Installment not found');

    if (inst.status === 'PAID') {
      throw new BadRequestException('Installment already paid');
    }

    const [updated] = await this.dataSource.query(
      `UPDATE installments SET status = 'PAID', paid_at = NOW(), payment_reference = $1, updated_at = NOW()
       WHERE id = $2 RETURNING *`,
      [paymentReference, installmentId],
    );

    const [remaining] = await this.dataSource.query(
      `SELECT COUNT(*)::int AS cnt FROM installments
       WHERE plan_id = $1 AND status != 'PAID'`,
      [inst.plan_id],
    );

    if (remaining.cnt === 0) {
      await this.dataSource.query(
        `UPDATE installment_plans SET status = 'COMPLETED', updated_at = NOW() WHERE id = $1`,
        [inst.plan_id],
      );
    }

    return updated;
  }

  // ── Installment overdue cron — daily at 7 AM ──

  @Cron('0 7 * * *')
  async handleInstallmentOverdue(): Promise<void> {
    const graced = await this.dataSource.query(
      `UPDATE installments
       SET status = 'GRACE', grace_expires_at = due_date + INTERVAL '7 days', updated_at = NOW()
       WHERE status = 'PENDING' AND due_date < CURRENT_DATE
       RETURNING id, plan_id`,
    );
    if (graced.length) {
      this.logger.log(`Moved ${graced.length} installments to GRACE`);
    }

    const overdue = await this.dataSource.query(
      `UPDATE installments
       SET status = 'OVERDUE', updated_at = NOW()
       WHERE status = 'GRACE' AND grace_expires_at < CURRENT_DATE
       RETURNING id, plan_id`,
    );
    if (overdue.length) {
      this.logger.log(`Moved ${overdue.length} installments to OVERDUE`);
      for (const o of overdue) {
        await this.dataSource.query(
          `UPDATE installment_plans SET status = 'DEFAULTED', updated_at = NOW() WHERE id = $1`,
          [o.plan_id],
        );
      }
    }
  }

  private generateReference(): string {
    const now = new Date();
    const date = now.toISOString().slice(0, 10).replace(/-/g, '');
    const rand = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `STN-${date}-${rand}`;
  }

  private rowToBooking(row: any): Booking {
    const b = new Booking();
    b.id = row.id;
    b.studentId = row.student_id;
    b.bedId = row.bed_id;
    b.status = row.status;
    b.reference = row.reference;
    b.pricePesewas = parseInt(row.price_pesewas, 10);
    b.platformFeePesewas = parseInt(row.platform_fee_pesewas, 10);
    b.totalPesewas = parseInt(row.total_pesewas, 10);
    b.heldUntil = row.held_until ? new Date(row.held_until) : null;
    b.periodLabel = row.period_label;
    b.checkInDate = row.check_in_date;
    b.cancelReason = row.cancel_reason;
    b.createdAt = new Date(row.created_at);
    b.updatedAt = new Date(row.updated_at);
    b.paymentType = row.payment_type || 'FULL';
    return b;
  }


  // ── Refund status ──
  async getRefund(bookingId: string, studentId: string) {
    const rows = await this.bookingRepo.query(
      `SELECT r.*, b.reference, b.student_id, h.name AS hostel_name
       FROM refunds r
       JOIN bookings b ON b.id = r.booking_id
       JOIN beds bd ON bd.id = b.bed_id
       JOIN rooms rm ON rm.id = bd.room_id
       JOIN floors f ON f.id = rm.floor_id
       JOIN buildings bl ON bl.id = f.building_id
       JOIN hostels h ON h.id = bl.hostel_id
       WHERE r.booking_id = $1 AND b.student_id = $2`,
      [bookingId, studentId],
    );
    if (!rows.length) return null;
    const r = rows[0];
    return {
      id: r.id,
      bookingId: r.booking_id,
      reference: r.reference,
      hostelName: r.hostel_name,
      amountPesewas: parseInt(r.amount_pesewas, 10),
      status: r.status,
      reason: r.reason,
      rejectReason: r.reject_reason,
      approvedAt: r.approved_at,
      refundedAt: r.refunded_at,
      createdAt: r.created_at,
      updatedAt: r.updated_at,
    };
  }

  async approveRefund(refundId: string, approve: boolean, rejectReason?: string) {
    if (approve) {
      await this.bookingRepo.query(
        `UPDATE refunds SET status = 'APPROVED', approved_at = NOW(), updated_at = NOW() WHERE id = $1 AND status = 'REQUESTED'`,
        [refundId],
      );
    } else {
      await this.bookingRepo.query(
        `UPDATE refunds SET status = 'REJECTED', reject_reason = $2, updated_at = NOW() WHERE id = $1 AND status = 'REQUESTED'`,
        [refundId, rejectReason ?? 'Rejected by owner'],
      );
    }
    const [updated] = await this.bookingRepo.query(`SELECT * FROM refunds WHERE id = $1`, [refundId]);
    return updated;
  }


  // ── Move-in Tasks ──

  async seedMoveInTasks(bookingId: string): Promise<void> {
    const defaultTasks = [
      { title: 'Security Clearance', description: 'Complete background verification with hostel security.', sortOrder: 1, status: 'PENDING', assignee: 'OWNER' },
      { title: 'Key Collection', description: 'Pick up your digital key card and room manual from the front office.', sortOrder: 2, status: 'CURRENT', assignee: 'STUDENT' },
      { title: 'Room Inspection', description: 'Inspect your room and report any pre-existing issues.', sortOrder: 3, status: 'PENDING', assignee: 'OWNER' },
    ];

    for (const task of defaultTasks) {
      await this.dataSource.query(
        `INSERT INTO move_in_tasks (booking_id, title, description, sort_order, status, assignee)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT DO NOTHING`,
        [bookingId, task.title, task.description, task.sortOrder, task.status, task.assignee],
      );
    }
  }

  async getMoveInTasks(bookingId: string, userId: string): Promise<any[]> {
    const rows = await this.dataSource.query(
      `SELECT t.* FROM move_in_tasks t
       JOIN bookings b ON b.id = t.booking_id
       WHERE t.booking_id = $1 AND b.student_id = $2
       ORDER BY t.sort_order ASC`,
      [bookingId, userId],
    );
    return rows;
  }

  async updateMoveInTask(taskId: string, userId: string, status: string): Promise<any> {
    const [task] = await this.dataSource.query(
      `SELECT t.*, b.student_id FROM move_in_tasks t
       JOIN bookings b ON b.id = t.booking_id
       WHERE t.id = $1`,
      [taskId],
    );
    if (!task) throw new NotFoundException('Task not found');
    if (task.student_id !== userId) throw new BadRequestException('Not your task');

    const completedAt = status === 'DONE' ? new Date().toISOString() : null;
    const [updated] = await this.dataSource.query(
      `UPDATE move_in_tasks SET status = $1, completed_at = $2, updated_at = NOW()
       WHERE id = $3 RETURNING *`,
      [status, completedAt, taskId],
    );

    // Auto-advance: if this task is DONE, set next PENDING to CURRENT
    if (status === 'DONE') {
      await this.dataSource.query(
        `UPDATE move_in_tasks SET status = 'CURRENT', updated_at = NOW()
         WHERE booking_id = $1 AND status = 'PENDING'
         AND sort_order = (SELECT MIN(sort_order) FROM move_in_tasks WHERE booking_id = $1 AND status = 'PENDING')`,
        [task.booking_id],
      );
    }

    return updated;
  }

  // ── Utility Bills ──

  async seedUtilityAccounts(bookingId: string): Promise<void> {
    const types = [
      { type: 'ELECTRICITY', credit: 852000, days: 12 },
      { type: 'WATER', credit: 0, days: 0 },
      { type: 'INTERNET', credit: 0, days: 0 },
    ];

    for (const u of types) {
      const [existing] = await this.dataSource.query(
        `SELECT id FROM utility_accounts WHERE booking_id = $1 AND utility_type = $2`,
        [bookingId, u.type],
      );
      if (existing) continue;

      const [account] = await this.dataSource.query(
        `INSERT INTO utility_accounts (booking_id, utility_type, credit_pesewas, estimated_days_left)
         VALUES ($1, $2, $3, $4) RETURNING id`,
        [bookingId, u.type, u.credit, u.days],
      );

      // Seed sample bills
      if (u.type === 'WATER') {
        await this.dataSource.query(
          `INSERT INTO utility_bills (account_id, label, utility_type, amount_pesewas, status, billing_period)
           VALUES ($1, 'Water Supply', 'WATER', 420000, 'SETTLED', 'May 2024 Billing')`,
          [account.id],
        );
      }
      if (u.type === 'INTERNET') {
        const dueDate = new Date();
        dueDate.setDate(dueDate.getDate() + 2);
        await this.dataSource.query(
          `INSERT INTO utility_bills (account_id, label, utility_type, amount_pesewas, status, billing_period, due_date)
           VALUES ($1, 'Premium Fiber', 'INTERNET', 1200000, 'PENDING', 'Unlimited Plan', $2)`,
          [account.id, dueDate.toISOString()],
        );
      }
    }
  }

  async getUtilityData(bookingId: string, userId: string): Promise<any> {
    // Verify ownership
    const [booking] = await this.dataSource.query(
      `SELECT id FROM bookings WHERE id = $1 AND student_id = $2`,
      [bookingId, userId],
    );
    if (!booking) throw new NotFoundException('Booking not found');

    const accounts = await this.dataSource.query(
      `SELECT * FROM utility_accounts WHERE booking_id = $1 ORDER BY utility_type`,
      [bookingId],
    );

    const accountIds = accounts.map((a: any) => a.id);
    let bills: any[] = [];
    if (accountIds.length > 0) {
      bills = await this.dataSource.query(
        `SELECT * FROM utility_bills WHERE account_id = ANY($1) ORDER BY created_at DESC`,
        [accountIds],
      );
    }

    return { accounts, bills };
  }


  // ── Student: add custom task ──
  async addCustomTask(bookingId: string, userId: string, title: string, description?: string): Promise<any> {
    const [booking] = await this.dataSource.query(
      `SELECT id FROM bookings WHERE id = $1 AND student_id = $2`, [bookingId, userId],
    );
    if (!booking) throw new NotFoundException('Booking not found');

    const [maxOrder] = await this.dataSource.query(
      `SELECT COALESCE(MAX(sort_order), 0) + 1 as next_order FROM move_in_tasks WHERE booking_id = $1`, [bookingId],
    );

    const [task] = await this.dataSource.query(
      `INSERT INTO move_in_tasks (booking_id, title, description, sort_order, status, assignee, custom)
       VALUES ($1, $2, $3, $4, 'PENDING', 'STUDENT', true) RETURNING *`,
      [bookingId, title, description || null, maxOrder.next_order],
    );
    return task;
  }

  // ── Student: delete custom task ──
  async deleteCustomTask(taskId: string, userId: string): Promise<void> {
    const [task] = await this.dataSource.query(
      `SELECT t.id, t.custom, b.student_id FROM move_in_tasks t
       JOIN bookings b ON b.id = t.booking_id WHERE t.id = $1`, [taskId],
    );
    if (!task) throw new NotFoundException('Task not found');
    if (task.student_id !== userId) throw new BadRequestException('Not your task');
    if (!task.custom) throw new BadRequestException('Cannot delete system tasks');
    await this.dataSource.query(`DELETE FROM move_in_tasks WHERE id = $1`, [taskId]);
  }

  // ── Owner: update task status ──
  async ownerUpdateTask(taskId: string, ownerId: string, status: string): Promise<any> {
    const [task] = await this.dataSource.query(
      `SELECT t.*, b.id as booking_id FROM move_in_tasks t
       JOIN bookings b ON b.id = t.booking_id
       JOIN beds ON beds.id = b.bed_id
       JOIN rooms r ON r.id = beds.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       JOIN hostels h ON h.id = bld.hostel_id
       WHERE t.id = $1 AND h.owner_id = $2`, [taskId, ownerId],
    );
    if (!task) throw new NotFoundException('Task not found or not your hostel');
    if (task.custom) throw new BadRequestException('Cannot modify student custom tasks');

    const completedAt = status === 'DONE' ? new Date().toISOString() : null;
    const [updated] = await this.dataSource.query(
      `UPDATE move_in_tasks SET status = $1, completed_at = $2, updated_at = NOW()
       WHERE id = $3 RETURNING *`,
      [status, completedAt, taskId],
    );

    // Auto-advance next PENDING to CURRENT
    if (status === 'DONE') {
      await this.dataSource.query(
        `UPDATE move_in_tasks SET status = 'CURRENT', updated_at = NOW()
         WHERE booking_id = $1 AND status = 'PENDING'
         AND sort_order = (SELECT MIN(sort_order) FROM move_in_tasks WHERE booking_id = $1 AND status = 'PENDING')`,
        [task.booking_id],
      );
    }
    return updated;
  }

  // ── Update check-in date (student, locks on CHECKED_IN) ──
  async updateCheckInDate(bookingId: string, userId: string, checkInDate: string): Promise<any> {
    const [booking] = await this.dataSource.query(
      `SELECT id, status FROM bookings WHERE id = $1 AND student_id = $2`, [bookingId, userId],
    );
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.status === 'CHECKED_IN' || booking.status === 'COMPLETED') {
      throw new BadRequestException('Cannot change date after check-in');
    }
    const [updated] = await this.dataSource.query(
      `UPDATE bookings SET check_in_date = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [checkInDate, bookingId],
    );
    return updated;
  }
}
