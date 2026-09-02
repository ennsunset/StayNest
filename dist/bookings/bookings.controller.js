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
Object.defineProperty(exports, "__esModule", { value: true });
exports.BookingsController = void 0;
const common_1 = require("@nestjs/common");
const bookings_service_1 = require("./bookings.service");
const visitors_service_1 = require("./visitors.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const roles_guard_1 = require("../auth/roles.guard");
const user_entity_1 = require("../users/entities/user.entity");
const bookings_dto_1 = require("./bookings.dto");
let BookingsController = class BookingsController {
    constructor(bookings, visitors) {
        this.bookings = bookings;
        this.visitors = visitors;
    }
    getRefund(id, req) {
        return this.bookings.getRefund(id, req.user.sub);
    }
    hold(req, dto) {
        return this.bookings.holdBed(req.user.sub, dto.bedId, dto.checkInDate, dto.duration, dto.paymentType);
    }
    myBookings(req) {
        return this.bookings.findByStudent(req.user.sub);
    }
    findOne(id) {
        return this.bookings.findById(id);
    }
    findByRef(reference) {
        return this.bookings.findByReference(reference);
    }
    getAgreement(id) {
        return this.bookings.getAgreement(id);
    }
    getRoommates(id) {
        return this.bookings.getRoommates(id);
    }
    createMaintenance(id, req, body) {
        return this.bookings.createMaintenance(id, req.user.sub, body);
    }
    getMaintenance(id) {
        return this.bookings.getMaintenance(id);
    }
    checkIn(id) {
        return this.bookings.checkIn(id);
    }
    signAgreement(id) {
        return this.bookings.signAgreement(id);
    }
    cancel(id, req, dto) {
        return this.bookings.cancel(id, req.user.sub, dto.reason);
    }
    confirm(id) {
        return this.bookings.confirm(id);
    }
    async checkInstallmentEligibility(req, hostelId) {
        return this.bookings.checkInstallmentEligibility(req.user.sub, hostelId);
    }
    async getInstallmentPlan(id) {
        const result = await this.bookings.getInstallmentPlan(id);
        if (!result)
            return { plan: null, installments: [] };
        return result;
    }
    async payInstallment(installmentId, body) {
        return this.bookings.payInstallment(installmentId, body.paymentReference);
    }
    async verifyVisitorPass(token) {
        return this.visitors.verifyPass(token);
    }
    async deleteVisitorPass(req, passId) {
        return this.visitors.deletePass(passId, req.user.sub);
    }
    async revokeVisitorPass(req, passId) {
        return this.visitors.revokePass(passId, req.user.sub);
    }
    async createVisitorPass(req, bookingId, body) {
        return this.visitors.createPass(req.user.sub, bookingId, body);
    }
    async getVisitorPasses(req, bookingId) {
        return this.visitors.getPassesForBooking(bookingId, req.user.sub);
    }
    async getMoveInTasks(bookingId, req) {
        return this.bookings.getMoveInTasks(bookingId, req.user.sub);
    }
    async updateMoveInTask(taskId, status, req) {
        return this.bookings.updateMoveInTask(taskId, req.user.sub, status);
    }
    async getUtilities(bookingId, req) {
        return this.bookings.getUtilityData(bookingId, req.user.sub);
    }
    async addCustomTask(bookingId, title, description, req) {
        return this.bookings.addCustomTask(bookingId, req.user.sub, title, description);
    }
    async deleteCustomTask(taskId, req) {
        return this.bookings.deleteCustomTask(taskId, req.user.sub);
    }
    async updateCheckInDate(bookingId, checkInDate, req) {
        return this.bookings.updateCheckInDate(bookingId, req.user.sub, checkInDate);
    }
    async ownerUpdateTask(taskId, status, req) {
        return this.bookings.ownerUpdateTask(taskId, req.user.sub, status);
    }
};
exports.BookingsController = BookingsController;
__decorate([
    (0, common_1.Get)(':id/refund'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.STUDENT),
    __param(0, (0, common_1.Param)('id', common_1.ParseUUIDPipe)),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "getRefund", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.STUDENT),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, bookings_dto_1.CreateBookingDto]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "hold", null);
__decorate([
    (0, common_1.Get)('mine'),
    (0, common_1.UseGuards)(roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.STUDENT),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "myBookings", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "findOne", null);
__decorate([
    (0, common_1.Get)('ref/:reference'),
    __param(0, (0, common_1.Param)('reference')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "findByRef", null);
__decorate([
    (0, common_1.Get)(':id/agreement'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "getAgreement", null);
__decorate([
    (0, common_1.Get)(':id/roommates'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "getRoommates", null);
__decorate([
    (0, common_1.Post)(':id/maintenance'),
    (0, common_1.UseGuards)(roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.STUDENT),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "createMaintenance", null);
__decorate([
    (0, common_1.Get)(':id/maintenance'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "getMaintenance", null);
__decorate([
    (0, common_1.Patch)(':id/check-in'),
    (0, common_1.UseGuards)(roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.OWNER),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "checkIn", null);
__decorate([
    (0, common_1.Patch)(':id/agreement/sign'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "signAgreement", null);
__decorate([
    (0, common_1.Patch)(':id/cancel'),
    (0, common_1.UseGuards)(roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.STUDENT),
    __param(0, (0, common_1.Param)('id', common_1.ParseUUIDPipe)),
    __param(1, (0, common_1.Req)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, bookings_dto_1.CancelBookingDto]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "cancel", null);
__decorate([
    (0, common_1.Patch)(':id/confirm'),
    __param(0, (0, common_1.Param)('id', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BookingsController.prototype, "confirm", null);
__decorate([
    (0, common_1.Get)('installment-eligibility/:hostelId'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('hostelId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "checkInstallmentEligibility", null);
__decorate([
    (0, common_1.Get)(':id/installments'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "getInstallmentPlan", null);
__decorate([
    (0, common_1.Patch)(':id/installments/:installmentId/pay'),
    __param(0, (0, common_1.Param)('installmentId')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "payInstallment", null);
__decorate([
    (0, common_1.Get)('visitors/verify/:token'),
    __param(0, (0, common_1.Param)('token')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "verifyVisitorPass", null);
__decorate([
    (0, common_1.Patch)('visitors/:passId/delete'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('passId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "deleteVisitorPass", null);
__decorate([
    (0, common_1.Patch)('visitors/:passId/revoke'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('passId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "revokeVisitorPass", null);
__decorate([
    (0, common_1.Post)(':id/visitors'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "createVisitorPass", null);
__decorate([
    (0, common_1.Get)(':id/visitors'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "getVisitorPasses", null);
__decorate([
    (0, common_1.Get)(':id/move-in-tasks'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "getMoveInTasks", null);
__decorate([
    (0, common_1.Patch)('move-in-tasks/:taskId'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('taskId')),
    __param(1, (0, common_1.Body)('status')),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "updateMoveInTask", null);
__decorate([
    (0, common_1.Get)(':id/utilities'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "getUtilities", null);
__decorate([
    (0, common_1.Post)(':id/move-in-tasks'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)('title')),
    __param(2, (0, common_1.Body)('description')),
    __param(3, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, Object]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "addCustomTask", null);
__decorate([
    (0, common_1.Delete)('move-in-tasks/:taskId'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('taskId')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "deleteCustomTask", null);
__decorate([
    (0, common_1.Patch)(':id/check-in-date'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)('checkInDate')),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "updateCheckInDate", null);
__decorate([
    (0, common_1.Patch)(':id/move-in-tasks/:taskId/owner'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.OWNER),
    __param(0, (0, common_1.Param)('taskId')),
    __param(1, (0, common_1.Body)('status')),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], BookingsController.prototype, "ownerUpdateTask", null);
exports.BookingsController = BookingsController = __decorate([
    (0, common_1.Controller)('bookings'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [bookings_service_1.BookingsService, visitors_service_1.VisitorsService])
], BookingsController);
//# sourceMappingURL=bookings.controller.js.map