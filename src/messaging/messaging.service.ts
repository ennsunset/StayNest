import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Conversation, Message } from './messaging.entity';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class MessagingService {
  constructor(
    @InjectRepository(Conversation)
    private convRepo: Repository<Conversation>,
    @InjectRepository(Message)
    private msgRepo: Repository<Message>,
    private readonly notificationsService: NotificationsService,
  ) {}

  async getOrCreateConversation(studentId: string, hostelId: string, ownerId: string): Promise<Conversation> {
    let conv = await this.convRepo.findOne({
      where: { studentId, hostelId },
    });
    if (!conv) {
      conv = this.convRepo.create({ studentId, hostelId, ownerId });
      await this.convRepo.save(conv);
    }
    return conv;
  }

  async getOrCreateDM(studentId: string, peerId: string) {
    const [existing] = await this.convRepo.query(
      `SELECT * FROM conversations
       WHERE type = 'DIRECT' AND (
         (student_id = $1 AND peer_id = $2) OR (student_id = $2 AND peer_id = $1)
       )`,
      [studentId, peerId],
    );
    if (existing) return existing;

    const [conv] = await this.convRepo.query(
      `INSERT INTO conversations (student_id, peer_id, type)
       VALUES ($1, $2, 'DIRECT') RETURNING *`,
      [studentId, peerId],
    );
    return conv;
  }

  async getConversationsForUser(userId: string, role: 'STUDENT' | 'OWNER'): Promise<any[]> {
    const where = role === 'STUDENT' ? { studentId: userId } : { ownerId: userId };
    const convs = await this.convRepo.find({
      where,
      order: { lastMessageAt: { direction: 'DESC', nulls: 'LAST' } as any },
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

  async getMessages(conversationId: string, userId: string, page = 1, limit = 50): Promise<{ data: Message[]; total: number }> {
    const conv = await this.convRepo.findOne({ where: { id: conversationId } });
    if (!conv) throw new NotFoundException('Conversation not found');
    if (conv.studentId !== userId && conv.ownerId !== userId) {
      throw new ForbiddenException('Not a participant');
    }

    // Mark messages as read
    const isStudent = conv.studentId === userId;
    if (isStudent) {
      await this.convRepo.update(conversationId, { unreadStudent: 0 });
    } else {
      await this.convRepo.update(conversationId, { unreadOwner: 0 });
    }
    await this.msgRepo.update(
      { conversationId, isRead: false, senderId: isStudent ? conv.ownerId : conv.studentId } as any,
      { isRead: true },
    );

    const [data, total] = await this.msgRepo.findAndCount({
      where: { conversationId },
      order: { createdAt: 'ASC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return { data, total };
  }

  async sendMessage(conversationId: string, senderId: string, body: string): Promise<Message> {
    const conv = await this.convRepo.findOne({ where: { id: conversationId } });
    if (!conv) throw new NotFoundException('Conversation not found');
    if (conv.studentId !== senderId && conv.ownerId !== senderId) {
      throw new ForbiddenException('Not a participant');
    }

    const msg = this.msgRepo.create({ conversationId, senderId, body });
    await this.msgRepo.save(msg);

    // Update conversation
    const isStudent = conv.studentId === senderId;
    await this.convRepo.update(conversationId, {
      lastMessage: body.length > 100 ? body.substring(0, 100) + '...' : body,
      lastMessageAt: new Date(),
      ...(isStudent ? { unreadOwner: () => 'unread_owner + 1' } : { unreadStudent: () => 'unread_student + 1' }),
    } as any);

    // Notify the recipient (non-blocking)
    const recipientId = isStudent ? conv.ownerId : conv.studentId;
    if (!recipientId) return msg;
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

  async deleteConversation(conversationId: string, userId: string): Promise<void> {
    const conv = await this.convRepo.findOne({ where: { id: conversationId } });
    if (!conv) throw new NotFoundException('Conversation not found');
    if (conv.studentId !== userId && conv.ownerId !== userId) {
      throw new ForbiddenException('Not a participant');
    }
    await this.msgRepo.delete({ conversationId });
    await this.convRepo.delete(conversationId);
  }
}
