import {
  Injectable, NotFoundException, BadRequestException, Logger,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Cron } from '@nestjs/schedule';
import * as crypto from 'crypto';

@Injectable()
export class VisitorsService {
  private readonly logger = new Logger(VisitorsService.name);

  constructor(private readonly dataSource: DataSource) {}

  // ── Generate visitor pass ──

  async createPass(studentId: string, bookingId: string, dto: {
    visitorName: string;
    visitorPhone?: string;
    purpose?: string;
  }) {
    // Validate booking belongs to student and is CHECKED_IN
    const [booking] = await this.dataSource.query(
      `SELECT b.id, b.student_id, b.status, bld.hostel_id
       FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       WHERE b.id = $1`,
      [bookingId],
    );

    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.student_id !== studentId) throw new BadRequestException('Not your booking');
    if (booking.status !== 'CHECKED_IN') {
      throw new BadRequestException('You must be checked in to generate visitor passes');
    }

    // Generate unique QR token
    const qrToken = `VP-${crypto.randomBytes(12).toString('hex').toUpperCase()}`;

    // Valid for 24 hours from now
    const validFrom = new Date();
    const validUntil = new Date(Date.now() + 24 * 60 * 60 * 1000);

    const [pass] = await this.dataSource.query(
      `INSERT INTO visitor_passes (booking_id, student_id, hostel_id, visitor_name, visitor_phone, purpose, qr_token, status, valid_from, valid_until)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'ACTIVE', $8, $9)
       RETURNING *`,
      [bookingId, studentId, booking.hostel_id, dto.visitorName, dto.visitorPhone || null, dto.purpose || null, qrToken, validFrom.toISOString(), validUntil.toISOString()],
    );

    return pass;
  }

  // ── List passes for a booking ──

  async getPassesForBooking(bookingId: string, studentId: string) {
    const passes = await this.dataSource.query(
      `SELECT * FROM visitor_passes
       WHERE booking_id = $1 AND student_id = $2
       ORDER BY created_at DESC`,
      [bookingId, studentId],
    );
    return passes;
  }

  // ── List passes for a hostel (owner view) ──

  async getPassesForHostel(hostelId: string) {
    const passes = await this.dataSource.query(
      `SELECT vp.*, u.full_name AS student_name
       FROM visitor_passes vp
       JOIN users u ON u.id = vp.student_id
       ORDER BY vp.created_at DESC
       LIMIT 100`,
    );
    // Filter by hostel
    return passes.filter((p: any) => p.hostel_id === hostelId);
  }

  // ── Verify / scan a pass ──

  async verifyPass(qrToken: string) {
    const [pass] = await this.dataSource.query(
      `SELECT vp.*, u.full_name AS student_name, h.name AS hostel_name
       FROM visitor_passes vp
       JOIN users u ON u.id = vp.student_id
       JOIN hostels h ON h.id = vp.hostel_id
       WHERE vp.qr_token = $1`,
      [qrToken],
    );

    if (!pass) {
      return { valid: false, reason: 'Pass not found' };
    }

    const now = new Date();

    if (pass.status === 'USED') {
      return { valid: false, reason: 'Pass already used', pass };
    }

    if (pass.status === 'EXPIRED') {
      return { valid: false, reason: 'Pass has expired', pass };
    }

    if (new Date(pass.valid_until) < now) {
      // Mark as expired
      await this.dataSource.query(
        `UPDATE visitor_passes SET status = 'EXPIRED', updated_at = NOW() WHERE id = $1`,
        [pass.id],
      );
      return { valid: false, reason: 'Pass has expired', pass: { ...pass, status: 'EXPIRED' } };
    }

    // Mark as used
    await this.dataSource.query(
      `UPDATE visitor_passes SET status = 'USED', used_at = NOW(), updated_at = NOW() WHERE id = $1`,
      [pass.id],
    );

    return {
      valid: true,
      pass: {
        ...pass,
        status: 'USED',
        used_at: now.toISOString(),
      },
      message: 'Valid pass. Please verify visitor ID.',
    };
  }

  // ── Revoke a pass ──

  async revokePass(passId: string, studentId: string) {
    const [pass] = await this.dataSource.query(
      `SELECT * FROM visitor_passes WHERE id = $1 AND student_id = $2`,
      [passId, studentId],
    );
    if (!pass) throw new NotFoundException('Pass not found');
    if (pass.status !== 'ACTIVE') {
      throw new BadRequestException('Can only revoke active passes');
    }

    await this.dataSource.query(
      `UPDATE visitor_passes SET status = 'REVOKED', updated_at = NOW() WHERE id = $1`,
      [passId],
    );
    return { success: true };
  }

  // ── Delete a pass (non-active only) ──

  async deletePass(passId: string, studentId: string) {
    const [pass] = await this.dataSource.query(
      `SELECT * FROM visitor_passes WHERE id = $1 AND student_id = $2`,
      [passId, studentId],
    );
    if (!pass) throw new NotFoundException('Pass not found');
    if (pass.status === 'ACTIVE') {
      throw new BadRequestException('Cannot delete an active pass. Revoke it first.');
    }
    await this.dataSource.query(`DELETE FROM visitor_passes WHERE id = $1`, [passId]);
    return { success: true };
  }

  // ── Expire old passes daily at midnight ──

  @Cron('0 0 * * *')
  async handleExpireOldPasses(): Promise<void> {
    const result = await this.dataSource.query(
      `UPDATE visitor_passes SET status = 'EXPIRED', updated_at = NOW()
       WHERE status = 'ACTIVE' AND valid_until < NOW()
       RETURNING id`,
    );
    if (result.length) {
      this.logger.log(`Expired ${result.length} visitor passes`);
    }
  }
}
