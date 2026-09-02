"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var PaymentsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const payment_entity_1 = require("./entities/payment.entity");
const booking_entity_1 = require("../bookings/entities/booking.entity");
const bookings_service_1 = require("../bookings/bookings.service");
const paystack_provider_1 = require("./paystack.provider");
let PaymentsService = PaymentsService_1 = class PaymentsService {
    constructor(paymentRepo, bookingRepo, dataSource, paystack, bookingsService) {
        this.paymentRepo = paymentRepo;
        this.bookingRepo = bookingRepo;
        this.dataSource = dataSource;
        this.paystack = paystack;
        this.bookingsService = bookingsService;
        this.logger = new common_1.Logger(PaymentsService_1.name);
    }
    async initializePayment(bookingId, studentId, email, callbackUrl, installmentId) {
        const booking = await this.bookingRepo.findOne({ where: { id: bookingId } });
        if (!booking)
            throw new common_1.NotFoundException('Booking not found');
        if (booking.studentId !== studentId)
            throw new common_1.BadRequestException('Not your booking');
        if (booking.status !== booking_entity_1.BookingStatus.HELD && booking.status !== booking_entity_1.BookingStatus.PENDING_PAYMENT) {
            throw new common_1.BadRequestException(`Cannot pay for a booking with status ${booking.status}`);
        }
        if (booking.status === booking_entity_1.BookingStatus.HELD && booking.heldUntil && new Date(booking.heldUntil) < new Date()) {
            throw new common_1.ConflictException('Hold has expired. Please book again.');
        }
        await this.paymentRepo.update({ bookingId, status: payment_entity_1.PaymentStatus.PENDING }, { status: payment_entity_1.PaymentStatus.ABANDONED });
        const suffix = Math.random().toString(36).substring(2, 6).toUpperCase();
        const paymentRef = `${booking.reference}-${suffix}`;
        const payment = this.paymentRepo.create({
            bookingId,
            providerReference: paymentRef,
            status: payment_entity_1.PaymentStatus.PENDING,
            amountPesewas: booking.paymentType === 'INSTALLMENT' ? Math.floor(Number(booking.totalPesewas) / 2) : booking.totalPesewas,
            currency: 'GHS',
        });
        await this.paymentRepo.save(payment);
        await this.bookingRepo.update(bookingId, { status: booking_entity_1.BookingStatus.PENDING_PAYMENT });
        let chargeAmount;
        if (installmentId) {
            const [inst] = await this.dataSource.query(`SELECT amount_pesewas FROM installments WHERE id = $1`, [installmentId]);
            if (!inst)
                throw new common_1.NotFoundException('Installment not found');
            chargeAmount = parseInt(inst.amount_pesewas, 10);
        }
        else if (booking.paymentType === 'INSTALLMENT') {
            chargeAmount = Math.floor(Number(booking.totalPesewas) / 2);
        }
        else {
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
    async handleWebhook(event, data) {
        if (event !== 'charge.success') {
            this.logger.log(`Ignoring webhook event: ${event}`);
            return;
        }
        const reference = data.reference;
        if (!reference) {
            this.logger.warn('Webhook missing reference');
            return;
        }
        const existing = await this.paymentRepo.findOne({
            where: { providerReference: reference },
        });
        if (existing && existing.status === payment_entity_1.PaymentStatus.SUCCESS) {
            this.logger.log(`Payment ${reference} already processed, skipping`);
            return;
        }
        try {
            const verified = await this.paystack.verify(reference);
            if (!verified.success) {
                this.logger.warn(`Verification failed for ${reference}: status=${verified.meta?.status}`);
                if (existing) {
                    await this.paymentRepo.update(existing.id, {
                        status: payment_entity_1.PaymentStatus.FAILED,
                        providerMeta: verified.meta,
                    });
                }
                return;
            }
            await this.dataSource.transaction(async (manager) => {
                let payment = existing;
                if (!payment) {
                    this.logger.warn(`Payment ${reference} not found, creating from webhook`);
                    const booking = await manager.findOne(booking_entity_1.Booking, {
                        where: { reference },
                    });
                    if (!booking) {
                        this.logger.error(`No booking found for reference ${reference}`);
                        return;
                    }
                    payment = manager.create(payment_entity_1.Payment, {
                        bookingId: booking.id,
                        providerReference: reference,
                        amountPesewas: verified.amountPesewas,
                        currency: verified.currency,
                    });
                }
                if (Number(payment.amountPesewas) !== verified.amountPesewas) {
                    this.logger.error(`Amount mismatch for ${reference}: expected ${payment.amountPesewas}, got ${verified.amountPesewas}`);
                    payment.status = payment_entity_1.PaymentStatus.FAILED;
                    payment.providerMeta = verified.meta;
                    await manager.save(payment_entity_1.Payment, payment);
                    return;
                }
                payment.status = payment_entity_1.PaymentStatus.SUCCESS;
                payment.providerId = verified.providerId;
                payment.channel = this.mapChannel(verified.channel);
                payment.providerMeta = verified.meta;
                await manager.save(payment_entity_1.Payment, payment);
                const booking = await manager.findOne(booking_entity_1.Booking, {
                    where: { id: payment.bookingId },
                });
                if (booking && (booking.status === booking_entity_1.BookingStatus.HELD || booking.status === booking_entity_1.BookingStatus.PENDING_PAYMENT)) {
                    await this.bookingsService.confirm(booking.id);
                    this.logger.log(`Booking ${booking.reference} confirmed via payment`);
                }
            });
        }
        catch (err) {
            this.logger.error(`Webhook processing failed for ${reference}: ${err.message}`);
        }
    }
    async verifyPayment(reference) {
        const payment = await this.paymentRepo.findOne({
            where: { providerReference: reference },
        });
        if (!payment)
            throw new common_1.NotFoundException('Payment not found');
        if (payment.status === payment_entity_1.PaymentStatus.PENDING) {
            const verified = await this.paystack.verify(reference);
            if (verified.success) {
                await this.handleWebhook('charge.success', verified.meta);
                return this.paymentRepo.findOne({ where: { id: payment.id } });
            }
        }
        return payment;
    }
    async getStudentHistory(studentId) {
        const rows = await this.paymentRepo.query(`
      SELECT
        p.id,
        p.amount_pesewas,
        p.status,
        p.channel,
        p.provider_reference,
        p.provider_meta,
        p.created_at,
        b.id AS booking_id,
        b.payment_type,
        h.name AS hostel_name
      FROM payments p
      JOIN bookings b ON b.id = p.booking_id
      JOIN beds bd ON bd.id = b.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE b.student_id = $1
        AND p.status = 'SUCCESS'
      ORDER BY p.created_at DESC
    `, [studentId]);
        const now = new Date();
        const yearStart = new Date(now.getFullYear(), 0, 1);
        let totalPaidYearPesewas = 0;
        const payments = rows.map((r) => {
            const amt = parseInt(r.amount_pesewas, 10);
            if (new Date(r.created_at) >= yearStart)
                totalPaidYearPesewas += amt;
            const meta = typeof r.provider_meta === 'string' ? JSON.parse(r.provider_meta) : r.provider_meta;
            const auth = meta?.authorization;
            return {
                id: r.id,
                amountPesewas: amt,
                status: r.status,
                channel: r.channel,
                reference: r.provider_reference,
                createdAt: r.created_at,
                bookingId: r.booking_id,
                paymentType: r.payment_type ?? 'FULL',
                hostelName: r.hostel_name,
                cardBrand: auth?.brand ?? null,
                cardLast4: auth?.last4 ?? null,
            };
        });
        return { totalPaidYearPesewas, payments };
    }
    mapChannel(channel) {
        switch (channel) {
            case 'mobile_money': return payment_entity_1.PaymentChannel.MOBILE_MONEY;
            case 'card': return payment_entity_1.PaymentChannel.CARD;
            case 'bank': return payment_entity_1.PaymentChannel.BANK;
            case 'ussd': return payment_entity_1.PaymentChannel.USSD;
            default: return null;
        }
    }
};
exports.PaymentsService = PaymentsService;
exports.PaymentsService = PaymentsService = PaymentsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(payment_entity_1.Payment)),
    __param(1, (0, typeorm_1.InjectRepository)(booking_entity_1.Booking)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.DataSource,
        paystack_provider_1.PaystackProvider,
        bookings_service_1.BookingsService])
], PaymentsService);
//# sourceMappingURL=payments.service.js.map