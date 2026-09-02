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
exports.Installment = exports.InstallmentPlan = void 0;
const typeorm_1 = require("typeorm");
const booking_entity_1 = require("./booking.entity");
let InstallmentPlan = class InstallmentPlan {
};
exports.InstallmentPlan = InstallmentPlan;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], InstallmentPlan.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => booking_entity_1.Booking, { nullable: false }),
    (0, typeorm_1.JoinColumn)({ name: 'booking_id' }),
    __metadata("design:type", booking_entity_1.Booking)
], InstallmentPlan.prototype, "booking", void 0);
__decorate([
    (0, typeorm_1.Index)({ unique: true }),
    (0, typeorm_1.Column)({ name: 'booking_id', type: 'uuid' }),
    __metadata("design:type", String)
], InstallmentPlan.prototype, "bookingId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', name: 'total_pesewas' }),
    __metadata("design:type", Number)
], InstallmentPlan.prototype, "totalPesewas", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', name: 'installment_count', default: 2 }),
    __metadata("design:type", Number)
], InstallmentPlan.prototype, "installmentCount", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20, default: 'ACTIVE' }),
    __metadata("design:type", String)
], InstallmentPlan.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], InstallmentPlan.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ type: 'timestamptz', name: 'updated_at' }),
    __metadata("design:type", Date)
], InstallmentPlan.prototype, "updatedAt", void 0);
exports.InstallmentPlan = InstallmentPlan = __decorate([
    (0, typeorm_1.Entity)('installment_plans')
], InstallmentPlan);
let Installment = class Installment {
};
exports.Installment = Installment;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Installment.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => InstallmentPlan, { nullable: false }),
    (0, typeorm_1.JoinColumn)({ name: 'plan_id' }),
    __metadata("design:type", InstallmentPlan)
], Installment.prototype, "plan", void 0);
__decorate([
    (0, typeorm_1.Index)(),
    (0, typeorm_1.Column)({ name: 'plan_id', type: 'uuid' }),
    __metadata("design:type", String)
], Installment.prototype, "planId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int' }),
    __metadata("design:type", Number)
], Installment.prototype, "sequence", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', name: 'amount_pesewas' }),
    __metadata("design:type", Number)
], Installment.prototype, "amountPesewas", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date', name: 'due_date' }),
    __metadata("design:type", String)
], Installment.prototype, "dueDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20, default: 'PENDING' }),
    __metadata("design:type", String)
], Installment.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamptz', nullable: true, name: 'paid_at' }),
    __metadata("design:type", Object)
], Installment.prototype, "paidAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 50, nullable: true, name: 'payment_reference' }),
    __metadata("design:type", Object)
], Installment.prototype, "paymentReference", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date', nullable: true, name: 'grace_expires_at' }),
    __metadata("design:type", Object)
], Installment.prototype, "graceExpiresAt", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], Installment.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ type: 'timestamptz', name: 'updated_at' }),
    __metadata("design:type", Date)
], Installment.prototype, "updatedAt", void 0);
exports.Installment = Installment = __decorate([
    (0, typeorm_1.Entity)('installments')
], Installment);
//# sourceMappingURL=installment.entity.js.map