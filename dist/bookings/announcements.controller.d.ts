import { AnnouncementsService } from './announcements.service';
export declare class AnnouncementsController {
    private readonly announcements;
    constructor(announcements: AnnouncementsService);
    create(req: any, hostelId: string, body: {
        title: string;
        body: string;
        priority?: string;
    }): Promise<any>;
    getForHostel(hostelId: string): Promise<any>;
    delete(req: any, id: string): Promise<{
        success: boolean;
    }>;
}
