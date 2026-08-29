// src/payments/payments.service.ts

import {
  Injectable, BadRequestException, ConflictException,
  NotFoundException, Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Payment, PaymentStatus, PaymentChannel } from './entities/payment.entity';
import { Booking, BookingStatus } from '../bookings/entities/booking.entity';
import { BookingsService } from '../bookings/bookings.service';
import { PaystackProvider } from './paystack.provider';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    @InjectRepository(Payment) private readonly paymentRepo: Repository<Payment>,
    @InjectRepository(Booking) private readonly bookingRepo: Repository<Booking>,
    private readonly dataSource: DataSource,
    private readonly paystack: PaystackProvider,
    private readonly bookingsService: BookingsService,
  ) {}

  // ── Initialize payment ────────────────────────────

  async initializePayment(bookingId: string, studentId: string, email: string, callbackUrl?: string, installmentId?: string) {
    // 1. Load booking
    const booking = await this.bookingRepo.findOne({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.studentId !== studentId) throw new BadRequestException('Not your booking');

    // 2. Only HELD or PENDING_PAYMENT bookings can be paid
    if (booking.status !== BookingStatus.HELD && booking.status !== BookingStatus.PENDING_PAYMENT) {
      throw new BadRequestException(`Cannot pay for a booking with status ${booking.status}`);
    }

    // 3. Check hold not expired (skip for PENDING_PAYMENT - student already started paying)
    if (booking.status === BookingStatus.HELD && booking.heldUntil && new Date(booking.heldUntil) < new Date()) {
      throw new ConflictException('Hold has expired. Please book again.');
    }

    // 4. Mark any stale PENDING payments as ABANDONED
    await this.paymentRepo.update(
      { bookingId, status: PaymentStatus.PENDING },
      { status: PaymentStatus.ABANDONED },
    );

    // 5. Create payment record - unique ref per attempt
    const suffix = Math.random().toString(36).substring(2, 6).toUpperCase();
    const paymentRef = `${booking.reference}-${suffix}`;

    const payment = this.paymentRepo.create({
      bookingId,
      providerReference: paymentRef,
      status: PaymentStatus.PENDING,
      amountPesewas: booking.paymentType === 'INSTALLMENT' ? Math.floor(Number(booking.totalPesewas) / 2) : booking.totalPesewas,
      currency: 'GHS',
    });
    await this.paymentRepo.save(payment);

    // 6. Transition booking to PENDING_PAYMENT
    await this.bookingRepo.update(bookingId, { status: BookingStatus.PENDING_PAYMENT });

    // 7. Initialize Paystack — use installment amount if paying a specific installment
    let chargeAmount: number;
    if (installmentId) {
      // Paying a specific installment (e.g. installment 2)
      const [inst] = await this.dataSource.query(
        `SELECT amount_pesewas FROM installments WHERE id = $1`,
        [installmentId],
      );
      if (!inst) throw new NotFoundException('Installment not found');
      chargeAmount = parseInt(inst.amount_pesewas, 10);
    } else if (booking.paymentType === 'INSTALLMENT') {
      chargeAmount = Math.floor(Number(booking.totalPesewas) / 2);
    } else {
      chargeAmount = Number(booking.totalPesewas);
    }
    const result = await this.paystack.initialize({
      reference: paymentRef,
      amountPesewas: chargeAmount,
      email,
      callbackUrl,
      metadata: { bookingId, bookingReference: booking.reference },
    });

    return {
      paymentId: payment.id,
      authorizationUrl: result.authorizationUrl,
      accessCode: result.accessCode,
      reference: paymentRef,
    };
  }

  // ── Webhook handler ───────────────────────────────

  /**
   * Called by Paystack webhook. Rules from handoff:
   * - Immediate 200 response (controller handles this)
   * - Deduplication by reference
   * - Server-side verify before granting value
   */
  async handleWebhook(event: string, data: any): Promise<void> {
    if (event !== 'charge.success') {
      this.logger.log(`Ignoring webhook event: ${event}`);
      return;
    }

    const reference = data.reference as string;
    if (!reference) {
      this.logger.warn('Webhook missing reference');
      return;
    }

    // Deduplication: skip if already processed
    const existing = await this.paymentRepo.findOne({
      where: { providerReference: reference },
    });

    if (existing && existing.status === PaymentStatus.SUCCESS) {
      this.logger.log(`Payment ${reference} already processed, skipping`);
      return;
    }

    // Server-side verify — never trust the webhook payload alone
    try {
      const verified = await this.paystack.verify(reference);

      if (!verified.success) {
        this.logger.warn(`Verification failed for ${reference}: status=${verified.meta?.status}`);
        if (existing) {
          await this.paymentRepo.update(existing.id, {
            status: PaymentStatus.FAILED,
            providerMeta: verified.meta,
          });
        }
        return;
      }

      // Process in a transaction
      await this.dataSource.transaction(async (manager) => {
        // Find or create payment record
        let payment = existing;
        if (!payment) {
          // Payment was not initialized through our API (edge case)
          this.logger.warn(`Payment ${reference} not found, creating from webhook`);
          const booking = await manager.findOne(Booking, {
            where: { reference },
          });
          if (!booking) {
            this.logger.error(`No booking found for reference ${reference}`);
            return;
          }
          payment = manager.create(Payment, {
            bookingId: booking.id,
            providerReference: reference,
            amountPesewas: verified.amountPesewas,
            currency: verified.currency,
          });
        }

        // Amount verification
        if (Number(payment.amountPesewas) !== verified.amountPesewas) {
          this.logger.error(
            `Amount mismatch for ${reference}: expected ${payment.amountPesewas}, got ${verified.amountPesewas}`,
          );
          payment.status = PaymentStatus.FAILED;
          payment.providerMeta = verified.meta;
          await manager.save(Payment, payment);
          return;
        }

        // Update payment
        payment.status = PaymentStatus.SUCCESS;
        payment.providerId = verified.providerId;
        payment.channel = this.mapChannel(verified.channel);
        payment.providerMeta = verified.meta;
        await manager.save(Payment, payment);

        // Confirm the booking
        const booking = await manager.findOne(Booking, {
          where: { id: payment.bookingId },
        });
        if (booking && (booking.status === BookingStatus.HELD || booking.status === BookingStatus.PENDING_PAYMENT)) {
          await this.bookingsService.confirm(booking.id);
          this.logger.log(`Booking ${booking.reference} confirmed via payment`);
        }
      });
    } catch (err) {
      this.logger.error(`Webhook processing failed for ${reference}: ${err.message}`);
    }
  }

  // ── Verify payment (client callback) ──────────────

  async verifyPayment(reference: string) {
    const payment = await this.paymentRepo.findOne({
      where: { providerReference: reference },
    });
    if (!payment) throw new NotFoundException('Payment not found');

    // If still pending, do a server-side check
    if (payment.status === PaymentStatus.PENDING) {
      const verified = await this.paystack.verify(reference);
      if (verified.success) {
        // Process it now (webhook may not have arrived yet)
        await this.handleWebhook('charge.success', verified.meta);
        // Reload
        return this.paymentRepo.findOne({ where: { id: payment.id } });
      }
    }

    return payment;
  }

  // ── Helpers ───────────────────────────────────────

  private mapChannel(channel: string): PaymentChannel | null {
    switch (channel) {
      case 'mobile_money': return PaymentChannel.MOBILE_MONEY;
      case 'card': return PaymentChannel.CARD;
      case 'bank': return PaymentChannel.BANK;
      case 'ussd': return PaymentChannel.USSD;
      default: return null;
    }
  }
}
