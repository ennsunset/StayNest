import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private repo: Repository<Notification>,
  ) {}

  async create(params: {
    userId: string;
    type: string;
    title: string;
    body: string;
    data?: Record<string, any>;
  }): Promise<Notification> {
    const notif = this.repo.create(params);
    return this.repo.save(notif);
  }

  async getForUser(userId: string, page = 1, limit = 20): Promise<{ data: Notification[]; total: number; unread: number }> {
    const [data, total] = await this.repo.findAndCount({
      where: { userId },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    const unread = await this.repo.count({ where: { userId, isRead: false } });
    return { data, total, unread };
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.repo.count({ where: { userId, isRead: false } });
  }

  async markAsRead(id: string, userId: string): Promise<void> {
    const result = await this.repo.query(
      'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2',
      [id, userId],
    );
    console.log('markAsRead:', { id, userId, result });
  }

  async delete(id: string, userId: string): Promise<void> {
    await this.repo.query(
      'DELETE FROM notifications WHERE id = $1 AND user_id = $2',
      [id, userId],
    );
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.repo.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
      [userId],
    );
  }
}
