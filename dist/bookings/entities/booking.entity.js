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
Object.defineProperty(exports, "__esModule", { value: true });
exports.Booking = exports.ACTIVE_BOOKING_STATUSES = exports.BookingStatus = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../../users/entities/user.entity");
const hostel_entity_1 = require("../../hostels/entities/hostel.entity");
var BookingStatus;
(function (BookingStatus) {
    BookingStatus["HELD"] = "HELD";
    BookingStatus["PENDING_PAYMENT"] = "PENDING_PAYMENT";
    BookingStatus["CONFIRMED"] = "CONFIRMED";
    BookingStatus["CHECKED_IN"] = "CHECKED_IN";
    BookingStatus["COMPLETED"] = "COMPLETED";
    BookingStatus["EXPIRED"] = "EXPIRED";
    BookingStatus["CANCELLED"] = "CANCELLED";
    BookingStatus["REFUNDED"] = "REFUNDED";
})(BookingStatus || (exports.BookingStatus = BookingStatus = {}));
exports.ACTIVE_BOOKING_STATUSES = [
    BookingStatus.HELD,
    BookingStatus.PENDING_PAYMENT,
    BookingStatus.CONFIRMED,
    BookingStatus.CHECKED_IN,
];
let Booking = class Booking {
};
exports.Booking = Booking;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Booking.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, { nullable: false }),
    (0, typeorm_1.JoinColumn)({ name: 'student_id' }),
    __metadata("design:type", user_entity_1.User)
], Booking.prototype, "student", void 0);
__decorate([
    (0, typeorm_1.Index)(),
    (0, typeorm_1.Column)({ name: 'student_id', type: 'uuid' }),
    __metadata("design:type", String)
], Booking.prototype, "studentId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => hostel_entity_1.Bed, { nullable: false }),
    (0, typeorm_1.JoinColumn)({ name: 'bed_id' }),
    __metadata("design:type", hostel_entity_1.Bed)
], Booking.prototype, "bed", void 0);
__decorate([
    (0, typeorm_1.Index)(),
    (0, typeorm_1.Column)({ name: 'bed_id', type: 'uuid' }),
    __metadata("design:type", String)
], Booking.prototype, "bedId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'enum', enum: BookingStatus, default: BookingStatus.HELD }),
    __metadata("design:type", String)
], Booking.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Index)({ unique: true }),
    (0, typeorm_1.Column)({ type: 'varchar', length: 20, name: 'reference' }),
    __metadata("design:type", String)
], Booking.prototype, "reference", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', name: 'price_pesewas' }),
    __metadata("design:type", Number)
], Booking.prototype, "pricePesewas", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', name: 'platform_fee_pesewas', default: 0 }),
    __metadata("design:type", Number)
], Booking.prototype, "platformFeePesewas", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', name: 'total_pesewas' }),
    __metadata("design:type", Number)
], Booking.prototype, "totalPesewas", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamptz', nullable: true, name: 'held_until' }),
    __metadata("design:type", Object)
], Booking.prototype, "heldUntil", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20, default: 'FULL_YEAR' }),
    __metadata("design:type", String)
], Booking.prototype, "duration", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 50, name: 'period_label', default: 'Full Academic Year' }),
    __metadata("design:type", String)
], Booking.prototype, "periodLabel", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date', nullable: true, name: 'check_in_date' }),
    __metadata("design:type", Object)
], Booking.prototype, "checkInDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true, name: 'cancel_reason' }),
    __metadata("design:type", Object)
], Booking.prototype, "cancelReason", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], Booking.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ type: 'timestamptz', name: 'updated_at' }),
    __metadata("design:type", Date)
], Booking.prototype, "updatedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamptz', name: 'agreement_signed_at', nullable: true }),
    __metadata("design:type", Date)
], Booking.prototype, "agreementSignedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20, default: 'FULL', name: 'payment_type' }),
    __metadata("design:type", String)
], Booking.prototype, "paymentType", void 0);
exports.Booking = Booking = __decorate([
    (0, typeorm_1.Entity)('bookings')
], Booking);
//# sourceMappingURL=booking.entity.js.map