import { DataSource } from 'typeorm';
import { NotificationsService } from '../notifications/notifications.service';
export declare class AnnouncementsService {
    private readonly dataSource;
    private readonly notifications;
    constructor(dataSource: DataSource, notifications: NotificationsService);
    create(ownerId: string, hostelId: string, dto: {
        title: string;
        body: string;
        priority?: string;
    }): Promise<any>;
    private notifyResidents;
    getForHostel(hostelId: string, limit?: number): Promise<any>;
    delete(announcementId: string, ownerId: string): Promise<{
        success: boolean;
    }>;
}
