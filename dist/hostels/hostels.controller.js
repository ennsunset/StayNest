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
exports.HostelsController = void 0;
const common_1 = require("@nestjs/common");
const hostels_service_1 = require("./hostels.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const roles_guard_1 = require("../auth/roles.guard");
const user_entity_1 = require("../users/entities/user.entity");
const hostels_dto_1 = require("./hostels.dto");
const search_hostels_dto_1 = require("./search-hostels.dto");
let HostelsController = class HostelsController {
    constructor(hostels) {
        this.hostels = hostels;
    }
    featured(university) {
        return this.hostels.findFeatured(university);
    }
    search(dto) {
        return this.hostels.search(dto);
    }
    searchCount(dto) {
        return this.hostels.searchCount(dto);
    }
    amenities() {
        return this.hostels.findAllAmenities();
    }
    roomDetail(roomId) {
        return this.hostels.findRoomById(roomId);
    }
    findOne(id) {
        return this.hostels.findById(id);
    }
    rooms(id) {
        return this.hostels.findRoomsByHostel(id);
    }
    create(req, dto) {
        return this.hostels.create(req.user.sub, dto);
    }
    myHostels(req) {
        return this.hostels.findAll({ ownerId: req.user.sub });
    }
    async softDelete(id, req) {
        await this.hostels.softDelete(id, req.user.sub, req.user.role);
        return { message: 'Hostel moved to trash. Will be permanently deleted after 60 days.' };
    }
    async restore(id, req) {
        await this.hostels.restore(id, req.user.sub, req.user.role);
        return { message: 'Hostel restored.' };
    }
};
exports.HostelsController = HostelsController;
__decorate([
    (0, common_1.Get)('featured'),
    __param(0, (0, common_1.Query)('university')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], HostelsController.prototype, "featured", null);
__decorate([
    (0, common_1.Get)('search'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [search_hostels_dto_1.SearchHostelsDto]),
    __metadata("design:returntype", void 0)
], HostelsController.prototype, "search", null);
__decorate([
    (0, common_1.Get)('search/count'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [search_hostels_dto_1.SearchHostelsDto]),
    __metadata("design:returntype", void 0)
], HostelsController.prototype, "searchCount", null);
__decorate([
    (0, common_1.Get)('amenities'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], HostelsController.prototype, "amenities", null);
__decorate([
    (0, common_1.Get)('rooms/:roomId'),
    __param(0, (0, common_1.Param)('roomId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], HostelsController.prototype, "roomDetail", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], HostelsController.prototype, "findOne", null);
__decorate([
    (0, common_1.Get)(':id/rooms'),
    __param(0, (0, common_1.Param)('id', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], HostelsController.prototype, "rooms", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.OWNER),
    (0, common_1.Post)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, hostels_dto_1.CreateHostelDto]),
    __metadata("design:returntype", void 0)
], HostelsController.prototype, "create", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.OWNER),
    (0, common_1.Get)('owner/mine'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], HostelsController.prototype, "myHostels", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id', common_1.ParseUUIDPipe)),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], HostelsController.prototype, "softDelete", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Patch)(':id/restore'),
    __param(0, (0, common_1.Param)('id', common_1.ParseUUIDPipe)),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], HostelsController.prototype, "restore", null);
exports.HostelsController = HostelsController = __decorate([
    (0, common_1.Controller)('hostels'),
    __metadata("design:paramtypes", [hostels_service_1.HostelsService])
], HostelsController);
//# sourceMappingURL=hostels.controller.js.map