import { Repository } from 'typeorm';
import { Conversation, Message } from './messaging.entity';
import { NotificationsService } from '../notifications/notifications.service';
export declare class MessagingService {
    private convRepo;
    private msgRepo;
    private readonly notificationsService;
    constructor(convRepo: Repository<Conversation>, msgRepo: Repository<Message>, notificationsService: NotificationsService);
    getOrCreateConversation(studentId: string, hostelId: string, ownerId: string): Promise<Conversation>;
    getOrCreateDM(studentId: string, peerId: string): Promise<any>;
    getConversationsForUser(userId: string, role: 'STUDENT' | 'OWNER'): Promise<any[]>;
    getMessages(conversationId: string, userId: string, page?: number, limit?: number): Promise<{
        data: Message[];
        total: number;
    }>;
    sendMessage(conversationId: string, senderId: string, body: string): Promise<Message>;
    deleteConversation(conversationId: string, userId: string): Promise<void>;
}
