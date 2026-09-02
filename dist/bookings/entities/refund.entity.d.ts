import { Booking } from './booking.entity';
export declare enum RefundStatus {
    REQUESTED = "REQUESTED",
    APPROVED = "APPROVED",
    PROCESSING = "PROCESSING",
    REFUNDED = "REFUNDED",
    REJECTED = "REJECTED"
}
export declare class Refund {
    id: string;
    bookingId: string;
    booking: Booking;
    amountPesewas: number;
    status: RefundStatus;
    reason: string | null;
    rejectReason: string | null;
    approvedAt: Date | null;
    refundedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
}
