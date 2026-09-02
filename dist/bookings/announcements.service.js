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
exports.AnnouncementsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("typeorm");
const notifications_service_1 = require("../notifications/notifications.service");
let AnnouncementsService = class AnnouncementsService {
    constructor(dataSource, notifications) {
        this.dataSource = dataSource;
        this.notifications = notifications;
    }
    async create(ownerId, hostelId, dto) {
        const [hostel] = await this.dataSource.query(`SELECT id FROM hostels WHERE id = $1 AND owner_id = $2`, [hostelId, ownerId]);
        if (!hostel)
            throw new common_1.ForbiddenException('Not your hostel');
        const [ann] = await this.dataSource.query(`INSERT INTO announcements (hostel_id, owner_id, title, body, priority)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`, [hostelId, ownerId, dto.title, dto.body, dto.priority || 'NORMAL']);
        this.notifyResidents(hostelId, ann).catch(() => { });
        return ann;
    }
    async notifyResidents(hostelId, ann) {
        const residents = await this.dataSource.query(`SELECT DISTINCT b.student_id FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       WHERE bld.hostel_id = $1 AND b.status = 'CHECKED_IN'`, [hostelId]);
        for (const r of residents) {
            await this.notifications.create({
                userId: r.student_id,
                type: 'ANNOUNCEMENT',
                title: ann.priority === 'URGENT' ? ann.title : ann.title,
                body: ann.body.length > 100 ? ann.body.substring(0, 100) + '...' : ann.body,
                data: { announcementId: ann.id, hostelId },
            }).catch(() => { });
        }
    }
    async getForHostel(hostelId, limit = 30) {
        return this.dataSource.query(`SELECT a.*, u.full_name AS author_name
       FROM announcements a
       JOIN users u ON u.id = a.owner_id
       WHERE a.hostel_id = $1 AND a.status = 'ACTIVE'
       ORDER BY a.created_at DESC LIMIT $2`, [hostelId, limit]);
    }
    async delete(announcementId, ownerId) {
        const [ann] = await this.dataSource.query(`SELECT * FROM announcements WHERE id = $1`, [announcementId]);
        if (!ann)
            throw new common_1.NotFoundException('Announcement not found');
        if (ann.owner_id !== ownerId)
            throw new common_1.ForbiddenException('Not your announcement');
        await this.dataSource.query(`UPDATE announcements SET status = 'DELETED', updated_at = NOW() WHERE id = $1`, [announcementId]);
        return { success: true };
    }
};
exports.AnnouncementsService = AnnouncementsService;
exports.AnnouncementsService = AnnouncementsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeorm_1.DataSource, notifications_service_1.NotificationsService])
], AnnouncementsService);
//# sourceMappingURL=announcements.service.js.map