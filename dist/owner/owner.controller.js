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
exports.OwnerController = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const roles_guard_1 = require("../auth/roles.guard");
const roles_guard_2 = require("../auth/roles.guard");
const user_entity_1 = require("../users/entities/user.entity");
const owner_service_1 = require("./owner.service");
let OwnerController = class OwnerController {
    constructor(ownerService) {
        this.ownerService = ownerService;
    }
    getHostels(req) {
        return this.ownerService.getHostels(req.user.sub);
    }
    getDashboard(req) {
        return this.ownerService.getDashboard(req.user.sub);
    }
    getBookings(req, status, page, limit) {
        return this.ownerService.getBookings(req.user.sub, {
            status,
            page: parseInt(page || '1', 10),
            limit: parseInt(limit || '20', 10),
        });
    }
    acceptBooking(req, bookingId) {
        return this.ownerService.acceptBooking(req.user.sub, bookingId);
    }
    declineBooking(req, bookingId, reason) {
        return this.ownerService.declineBooking(req.user.sub, bookingId, reason);
    }
    getTenants(req) {
        return this.ownerService.getTenants(req.user.sub);
    }
    getPayments(req, page, limit) {
        return this.ownerService.getPayments(req.user.sub, {
            page: parseInt(page || '1', 10),
            limit: parseInt(limit || '20', 10),
        });
    }
    getRooms(req, hostelId) {
        return this.ownerService.getRoomsForHostel(req.user.sub, hostelId);
    }
    getFloors(req, hostelId) {
        return this.ownerService.getFloorsForHostel(req.user.sub, hostelId);
    }
    createRoom(req, hostelId, dto) {
        return this.ownerService.createRoom(req.user.sub, hostelId, dto);
    }
    updateRoom(req, roomId, dto) {
        return this.ownerService.updateRoom(req.user.sub, roomId, dto);
    }
    getBeds(req, roomId) {
        return this.ownerService.getBedsForRoom(req.user.sub, roomId);
    }
    addBeds(req, roomId, count) {
        return this.ownerService.addBeds(req.user.sub, roomId, count);
    }
    updateBedStatus(req, bedId, status) {
        return this.ownerService.updateBedStatus(req.user.sub, bedId, status);
    }
    checkoutBed(req, bedId) {
        return this.ownerService.checkoutBed(req.user.sub, bedId);
    }
    deleteBed(req, bedId) {
        return this.ownerService.deleteBed(req.user.sub, bedId);
    }
    createHostel(req, body) {
        return this.ownerService.createHostel(req.user.sub, body);
    }
    submitHostel(req, hostelId) {
        return this.ownerService.submitHostel(req.user.sub, hostelId);
    }
    getHostel(req, hostelId) {
        return this.ownerService.getHostel(req.user.sub, hostelId);
    }
    updateHostel(req, hostelId, body) {
        return this.ownerService.updateHostel(req.user.sub, hostelId, body);
    }
};
exports.OwnerController = OwnerController;
__decorate([
    (0, common_1.Get)('hostels'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "getHostels", null);
__decorate([
    (0, common_1.Get)('dashboard'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "getDashboard", null);
__decorate([
    (0, common_1.Get)('bookings'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('status')),
    __param(2, (0, common_1.Query)('page')),
    __param(3, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "getBookings", null);
__decorate([
    (0, common_1.Patch)('bookings/:id/accept'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "acceptBooking", null);
__decorate([
    (0, common_1.Patch)('bookings/:id/decline'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)('reason')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "declineBooking", null);
__decorate([
    (0, common_1.Get)('tenants'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "getTenants", null);
__decorate([
    (0, common_1.Get)('payments'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('page')),
    __param(2, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "getPayments", null);
__decorate([
    (0, common_1.Get)('hostels/:hostelId/rooms'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('hostelId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "getRooms", null);
__decorate([
    (0, common_1.Get)('hostels/:hostelId/floors'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('hostelId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "getFloors", null);
__decorate([
    (0, common_1.Post)('hostels/:hostelId/rooms'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('hostelId', common_1.ParseUUIDPipe)),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "createRoom", null);
__decorate([
    (0, common_1.Patch)('rooms/:roomId'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('roomId', common_1.ParseUUIDPipe)),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "updateRoom", null);
__decorate([
    (0, common_1.Get)('rooms/:roomId/beds'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('roomId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "getBeds", null);
__decorate([
    (0, common_1.Post)('rooms/:roomId/beds'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('roomId', common_1.ParseUUIDPipe)),
    __param(2, (0, common_1.Body)('count')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Number]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "addBeds", null);
__decorate([
    (0, common_1.Patch)('beds/:bedId/status'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('bedId', common_1.ParseUUIDPipe)),
    __param(2, (0, common_1.Body)('status')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "updateBedStatus", null);
__decorate([
    (0, common_1.Patch)('beds/:bedId/checkout'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('bedId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "checkoutBed", null);
__decorate([
    (0, common_1.Delete)('beds/:bedId'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('bedId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "deleteBed", null);
__decorate([
    (0, common_1.Post)('hostels'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "createHostel", null);
__decorate([
    (0, common_1.Patch)('hostels/:hostelId/submit'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('hostelId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "submitHostel", null);
__decorate([
    (0, common_1.Get)('hostels/:hostelId'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('hostelId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "getHostel", null);
__decorate([
    (0, common_1.Patch)('hostels/:hostelId'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('hostelId', common_1.ParseUUIDPipe)),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], OwnerController.prototype, "updateHostel", null);
exports.OwnerController = OwnerController = __decorate([
    (0, common_1.Controller)('owner'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_guard_2.Roles)(user_entity_1.UserRole.OWNER),
    __metadata("design:paramtypes", [owner_service_1.OwnerService])
], OwnerController);
//# sourceMappingURL=owner.controller.js.map