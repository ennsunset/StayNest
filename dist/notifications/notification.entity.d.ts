import { User } from '../users/entities/user.entity';
export declare class Notification {
    id: string;
    user: User;
    userId: string;
    type: string;
    title: string;
    body: string;
    data: Record<string, any> | null;
    isRead: boolean;
    createdAt: Date;
}
