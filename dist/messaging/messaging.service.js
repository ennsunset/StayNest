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
exports.MessagingService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const messaging_entity_1 = require("./messaging.entity");
const notifications_service_1 = require("../notifications/notifications.service");
let MessagingService = class MessagingService {
    constructor(convRepo, msgRepo, notificationsService) {
        this.convRepo = convRepo;
        this.msgRepo = msgRepo;
        this.notificationsService = notificationsService;
    }
    async getOrCreateConversation(studentId, hostelId, ownerId) {
        let conv = await this.convRepo.findOne({
            where: { studentId, hostelId },
        });
        if (!conv) {
            conv = this.convRepo.create({ studentId, hostelId, ownerId });
            await this.convRepo.save(conv);
        }
        return conv;
    }
    async getOrCreateDM(studentId, peerId) {
        const [existing] = await this.convRepo.query(`SELECT * FROM conversations
       WHERE type = 'DIRECT' AND (
         (student_id = $1 AND peer_id = $2) OR (student_id = $2 AND peer_id = $1)
       )`, [studentId, peerId]);
        if (existing)
            return existing;
        const [conv] = await this.convRepo.query(`INSERT INTO conversations (student_id, peer_id, type)
       VALUES ($1, $2, 'DIRECT') RETURNING *`, [studentId, peerId]);
        return conv;
    }
    async getConversationsForUser(userId, role) {
        const where = role === 'STUDENT' ? { studentId: userId } : { ownerId: userId };
        const convs = await this.convRepo.find({
            where,
            order: { lastMessageAt: { direction: 'DESC', nulls: 'LAST' } },
            relations: ['hostel', 'student'],
        });
        return convs.map(c => ({
            id: c.id,
            hostelId: c.hostelId,
            hostelName: c.hostel?.name ?? 'Unknown Hostel',
            studentId: c.studentId,
            ownerId: c.ownerId,
            lastMessage: c.lastMessage,
            lastMessageAt: c.lastMessageAt,
            unread: role === 'STUDENT' ? c.unreadStudent : c.unreadOwner,
            studentName: c.student?.fullName ?? 'Student',
            createdAt: c.createdAt,
        }));
    }
    async getMessages(conversationId, userId, page = 1, limit = 50) {
        const conv = await this.convRepo.findOne({ where: { id: conversationId } });
        if (!conv)
            throw new common_1.NotFoundException('Conversation not found');
        if (conv.studentId !== userId && conv.ownerId !== userId) {
            throw new common_1.ForbiddenException('Not a participant');
        }
        const isStudent = conv.studentId === userId;
        if (isStudent) {
            await this.convRepo.update(conversationId, { unreadStudent: 0 });
        }
        else {
            await this.convRepo.update(conversationId, { unreadOwner: 0 });
        }
        await this.msgRepo.update({ conversationId, isRead: false, senderId: isStudent ? conv.ownerId : conv.studentId }, { isRead: true });
        const [data, total] = await this.msgRepo.findAndCount({
            where: { conversationId },
            order: { createdAt: 'ASC' },
            skip: (page - 1) * limit,
            take: limit,
        });
        return { data, total };
    }
    async sendMessage(conversationId, senderId, body) {
        const conv = await this.convRepo.findOne({ where: { id: conversationId } });
        if (!conv)
            throw new common_1.NotFoundException('Conversation not found');
        if (conv.studentId !== senderId && conv.ownerId !== senderId) {
            throw new common_1.ForbiddenException('Not a participant');
        }
        const msg = this.msgRepo.create({ conversationId, senderId, body });
        await this.msgRepo.save(msg);
        const isStudent = conv.studentId === senderId;
        await this.convRepo.update(conversationId, {
            lastMessage: body.length > 100 ? body.substring(0, 100) + '...' : body,
            lastMessageAt: new Date(),
            ...(isStudent ? { unreadOwner: () => 'unread_owner + 1' } : { unreadStudent: () => 'unread_student + 1' }),
        });
        const recipientId = isStudent ? conv.ownerId : conv.studentId;
        if (!recipientId)
            return msg;
        const senderLabel = isStudent ? 'A student' : 'Hostel owner';
        this.notificationsService.create({
            userId: recipientId,
            type: 'NEW_MESSAGE',
            title: 'New Message',
            body: `${senderLabel} sent you a message`,
            data: { conversationId },
        }).catch((err) => console.error('NOTIFY ERROR:', err.message));
        return msg;
    }
    async deleteConversation(conversationId, userId) {
        const conv = await this.convRepo.findOne({ where: { id: conversationId } });
        if (!conv)
            throw new common_1.NotFoundException('Conversation not found');
        if (conv.studentId !== userId && conv.ownerId !== userId) {
            throw new common_1.ForbiddenException('Not a participant');
        }
        await this.msgRepo.delete({ conversationId });
        await this.convRepo.delete(conversationId);
    }
};
exports.MessagingService = MessagingService;
exports.MessagingService = MessagingService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(messaging_entity_1.Conversation)),
    __param(1, (0, typeorm_1.InjectRepository)(messaging_entity_1.Message)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        notifications_service_1.NotificationsService])
], MessagingService);
//# sourceMappingURL=messaging.service.js.map