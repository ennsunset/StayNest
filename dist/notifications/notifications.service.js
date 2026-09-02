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
exports.NotificationsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const notification_entity_1 = require("./notification.entity");
let NotificationsService = class NotificationsService {
    constructor(repo) {
        this.repo = repo;
    }
    async create(params) {
        const notif = this.repo.create(params);
        return this.repo.save(notif);
    }
    async getForUser(userId, page = 1, limit = 20) {
        const [data, total] = await this.repo.findAndCount({
            where: { userId },
            order: { createdAt: 'DESC' },
            skip: (page - 1) * limit,
            take: limit,
        });
        const unread = await this.repo.count({ where: { userId, isRead: false } });
        return { data, total, unread };
    }
    async getUnreadCount(userId) {
        return this.repo.count({ where: { userId, isRead: false } });
    }
    async markAsRead(id, userId) {
        const result = await this.repo.query('UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2', [id, userId]);
        console.log('markAsRead:', { id, userId, result });
    }
    async delete(id, userId) {
        await this.repo.query('DELETE FROM notifications WHERE id = $1 AND user_id = $2', [id, userId]);
    }
    async markAllAsRead(userId) {
        await this.repo.query('UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false', [userId]);
    }
};
exports.NotificationsService = NotificationsService;
exports.NotificationsService = NotificationsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(notification_entity_1.Notification)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], NotificationsService);
//# sourceMappingURL=notifications.service.js.map