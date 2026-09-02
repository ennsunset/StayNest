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
exports.UtilityBill = exports.UtilityAccount = exports.BillStatus = exports.UtilityType = void 0;
const typeorm_1 = require("typeorm");
var UtilityType;
(function (UtilityType) {
    UtilityType["ELECTRICITY"] = "ELECTRICITY";
    UtilityType["WATER"] = "WATER";
    UtilityType["INTERNET"] = "INTERNET";
})(UtilityType || (exports.UtilityType = UtilityType = {}));
var BillStatus;
(function (BillStatus) {
    BillStatus["PENDING"] = "PENDING";
    BillStatus["SETTLED"] = "SETTLED";
    BillStatus["OVERDUE"] = "OVERDUE";
})(BillStatus || (exports.BillStatus = BillStatus = {}));
let UtilityAccount = class UtilityAccount {
};
exports.UtilityAccount = UtilityAccount;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], UtilityAccount.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'uuid', name: 'booking_id' }),
    __metadata("design:type", String)
], UtilityAccount.prototype, "bookingId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20, name: 'utility_type' }),
    __metadata("design:type", String)
], UtilityAccount.prototype, "utilityType", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', name: 'credit_pesewas', default: 0 }),
    __metadata("design:type", Number)
], UtilityAccount.prototype, "creditPesewas", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', name: 'estimated_days_left', default: 0 }),
    __metadata("design:type", Number)
], UtilityAccount.prototype, "estimatedDaysLeft", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], UtilityAccount.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ type: 'timestamptz', name: 'updated_at' }),
    __metadata("design:type", Date)
], UtilityAccount.prototype, "updatedAt", void 0);
exports.UtilityAccount = UtilityAccount = __decorate([
    (0, typeorm_1.Entity)('utility_accounts')
], UtilityAccount);
let UtilityBill = class UtilityBill {
};
exports.UtilityBill = UtilityBill;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], UtilityBill.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'uuid', name: 'account_id' }),
    __metadata("design:type", String)
], UtilityBill.prototype, "accountId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 100 }),
    __metadata("design:type", String)
], UtilityBill.prototype, "label", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], UtilityBill.prototype, "description", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20, name: 'utility_type' }),
    __metadata("design:type", String)
], UtilityBill.prototype, "utilityType", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', name: 'amount_pesewas' }),
    __metadata("design:type", Number)
], UtilityBill.prototype, "amountPesewas", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20, default: BillStatus.PENDING }),
    __metadata("design:type", String)
], UtilityBill.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 50, nullable: true, name: 'billing_period' }),
    __metadata("design:type", String)
], UtilityBill.prototype, "billingPeriod", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamptz', nullable: true, name: 'due_date' }),
    __metadata("design:type", Object)
], UtilityBill.prototype, "dueDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamptz', nullable: true, name: 'paid_at' }),
    __metadata("design:type", Object)
], UtilityBill.prototype, "paidAt", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], UtilityBill.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ type: 'timestamptz', name: 'updated_at' }),
    __metadata("design:type", Date)
], UtilityBill.prototype, "updatedAt", void 0);
exports.UtilityBill = UtilityBill = __decorate([
    (0, typeorm_1.Entity)('utility_bills')
], UtilityBill);
//# sourceMappingURL=utility_account.entity.js.map