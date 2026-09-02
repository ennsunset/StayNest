import { NotificationsService } from './notifications.service';
export declare class NotificationsController {
    private svc;
    constructor(svc: NotificationsService);
    list(req: any, page?: string): Promise<{
        data: import("./notification.entity").Notification[];
        total: number;
        unread: number;
    }>;
    unreadCount(req: any): Promise<{
        count: number;
    }>;
    markAllRead(req: any): Promise<{
        success: boolean;
    }>;
    markRead(req: any, id: string): Promise<{
        success: boolean;
    }>;
    delete(req: any, id: string): Promise<{
        success: boolean;
    }>;
}
