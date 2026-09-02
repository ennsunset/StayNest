import { User } from '../../users/entities/user.entity';
import { Bed } from '../../hostels/entities/hostel.entity';
export declare enum BookingStatus {
    HELD = "HELD",
    PENDING_PAYMENT = "PENDING_PAYMENT",
    CONFIRMED = "CONFIRMED",
    CHECKED_IN = "CHECKED_IN",
    COMPLETED = "COMPLETED",
    EXPIRED = "EXPIRED",
    CANCELLED = "CANCELLED",
    REFUNDED = "REFUNDED"
}
export declare const ACTIVE_BOOKING_STATUSES: BookingStatus[];
export declare class Booking {
    id: string;
    student: User;
    studentId: string;
    bed: Bed;
    bedId: string;
    status: BookingStatus;
    reference: string;
    pricePesewas: number;
    platformFeePesewas: number;
    totalPesewas: number;
    heldUntil: Date | null;
    duration: string;
    periodLabel: string;
    checkInDate: string | null;
    cancelReason: string | null;
    createdAt: Date;
    updatedAt: Date;
    agreementSignedAt: Date;
    paymentType: string;
}
