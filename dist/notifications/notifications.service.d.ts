import { Repository } from 'typeorm';
import { Notification } from './notification.entity';
export declare class NotificationsService {
    private repo;
    constructor(repo: Repository<Notification>);
    create(params: {
        userId: string;
        type: string;
        title: string;
        body: string;
        data?: Record<string, any>;
    }): Promise<Notification>;
    getForUser(userId: string, page?: number, limit?: number): Promise<{
        data: Notification[];
        total: number;
        unread: number;
    }>;
    getUnreadCount(userId: string): Promise<number>;
    markAsRead(id: string, userId: string): Promise<void>;
    delete(id: string, userId: string): Promise<void>;
    markAllAsRead(userId: string): Promise<void>;
}
