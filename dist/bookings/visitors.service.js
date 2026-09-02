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
var VisitorsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.VisitorsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("typeorm");
const schedule_1 = require("@nestjs/schedule");
const crypto = require("crypto");
let VisitorsService = VisitorsService_1 = class VisitorsService {
    constructor(dataSource) {
        this.dataSource = dataSource;
        this.logger = new common_1.Logger(VisitorsService_1.name);
    }
    async createPass(studentId, bookingId, dto) {
        const [booking] = await this.dataSource.query(`SELECT b.id, b.student_id, b.status, bld.hostel_id
       FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       WHERE b.id = $1`, [bookingId]);
        if (!booking)
            throw new common_1.NotFoundException('Booking not found');
        if (booking.student_id !== studentId)
            throw new common_1.BadRequestException('Not your booking');
        if (booking.status !== 'CHECKED_IN') {
            throw new common_1.BadRequestException('You must be checked in to generate visitor passes');
        }
        const qrToken = `VP-${crypto.randomBytes(12).toString('hex').toUpperCase()}`;
        const validFrom = new Date();
        const validUntil = new Date(Date.now() + 24 * 60 * 60 * 1000);
        const [pass] = await this.dataSource.query(`INSERT INTO visitor_passes (booking_id, student_id, hostel_id, visitor_name, visitor_phone, purpose, qr_token, status, valid_from, valid_until)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'ACTIVE', $8, $9)
       RETURNING *`, [bookingId, studentId, booking.hostel_id, dto.visitorName, dto.visitorPhone || null, dto.purpose || null, qrToken, validFrom.toISOString(), validUntil.toISOString()]);
        return pass;
    }
    async getPassesForBooking(bookingId, studentId) {
        const passes = await this.dataSource.query(`SELECT * FROM visitor_passes
       WHERE booking_id = $1 AND student_id = $2
       ORDER BY created_at DESC`, [bookingId, studentId]);
        return passes;
    }
    async getPassesForHostel(hostelId) {
        const passes = await this.dataSource.query(`SELECT vp.*, u.full_name AS student_name
       FROM visitor_passes vp
       JOIN users u ON u.id = vp.student_id
       ORDER BY vp.created_at DESC
       LIMIT 100`);
        return passes.filter((p) => p.hostel_id === hostelId);
    }
    async verifyPass(qrToken) {
        const [pass] = await this.dataSource.query(`SELECT vp.*, u.full_name AS student_name, h.name AS hostel_name
       FROM visitor_passes vp
       JOIN users u ON u.id = vp.student_id
       JOIN hostels h ON h.id = vp.hostel_id
       WHERE vp.qr_token = $1`, [qrToken]);
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
            await this.dataSource.query(`UPDATE visitor_passes SET status = 'EXPIRED', updated_at = NOW() WHERE id = $1`, [pass.id]);
            return { valid: false, reason: 'Pass has expired', pass: { ...pass, status: 'EXPIRED' } };
        }
        await this.dataSource.query(`UPDATE visitor_passes SET status = 'USED', used_at = NOW(), updated_at = NOW() WHERE id = $1`, [pass.id]);
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
    async revokePass(passId, studentId) {
        const [pass] = await this.dataSource.query(`SELECT * FROM visitor_passes WHERE id = $1 AND student_id = $2`, [passId, studentId]);
        if (!pass)
            throw new common_1.NotFoundException('Pass not found');
        if (pass.status !== 'ACTIVE') {
            throw new common_1.BadRequestException('Can only revoke active passes');
        }
        await this.dataSource.query(`UPDATE visitor_passes SET status = 'REVOKED', updated_at = NOW() WHERE id = $1`, [passId]);
        return { success: true };
    }
    async deletePass(passId, studentId) {
        const [pass] = await this.dataSource.query(`SELECT * FROM visitor_passes WHERE id = $1 AND student_id = $2`, [passId, studentId]);
        if (!pass)
            throw new common_1.NotFoundException('Pass not found');
        if (pass.status === 'ACTIVE') {
            throw new common_1.BadRequestException('Cannot delete an active pass. Revoke it first.');
        }
        await this.dataSource.query(`DELETE FROM visitor_passes WHERE id = $1`, [passId]);
        return { success: true };
    }
    async handleExpireOldPasses() {
        const result = await this.dataSource.query(`UPDATE visitor_passes SET status = 'EXPIRED', updated_at = NOW()
       WHERE status = 'ACTIVE' AND valid_until < NOW()
       RETURNING id`);
        if (result.length) {
            this.logger.log(`Expired ${result.length} visitor passes`);
        }
    }
};
exports.VisitorsService = VisitorsService;
__decorate([
    (0, schedule_1.Cron)('0 0 * * *'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], VisitorsService.prototype, "handleExpireOldPasses", null);
exports.VisitorsService = VisitorsService = VisitorsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeorm_1.DataSource])
], VisitorsService);
//# sourceMappingURL=visitors.service.js.map