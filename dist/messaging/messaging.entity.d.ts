import { User } from '../users/entities/user.entity';
import { Hostel } from '../hostels/entities/hostel.entity';
export declare class Conversation {
    id: string;
    hostel: Hostel;
    hostelId: string;
    student: User;
    studentId: string;
    owner: User;
    ownerId: string;
    lastMessage: string | null;
    lastMessageAt: Date | null;
    unreadStudent: number;
    unreadOwner: number;
    createdAt: Date;
    updatedAt: Date;
}
export declare class Message {
    id: string;
    conversationId: string;
    senderId: string;
    body: string;
    isRead: boolean;
    createdAt: Date;
}
