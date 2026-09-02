import { Booking } from './booking.entity';
export declare enum TaskStatus {
    PENDING = "PENDING",
    CURRENT = "CURRENT",
    DONE = "DONE"
}
export declare class MoveInTask {
    id: string;
    bookingId: string;
    booking: Booking;
    title: string;
    description: string;
    sortOrder: number;
    status: TaskStatus;
    completedAt: Date | null;
    assignee: string;
    custom: boolean;
    createdAt: Date;
    updatedAt: Date;
}
