import { MessagingService } from './messaging.service';
export declare class MessagingController {
    private readonly messagingService;
    constructor(messagingService: MessagingService);
    getOrCreate(req: any, body: {
        hostelId: string;
        ownerId: string;
    }): Promise<import("./messaging.entity").Conversation>;
    createDM(req: any, body: {
        peerId: string;
    }): Promise<any>;
    listConversations(req: any, role?: string): Promise<any[]>;
    getMessages(req: any, id: string, page?: string): Promise<{
        data: import("./messaging.entity").Message[];
        total: number;
    }>;
    sendMessage(req: any, id: string, body: {
        body: string;
    }): Promise<import("./messaging.entity").Message>;
    deleteConversation(req: any, id: string): Promise<{
        deleted: boolean;
    }>;
}
