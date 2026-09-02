import { Booking } from '../../bookings/entities/booking.entity';
export declare enum PaymentStatus {
    PENDING = "PENDING",
    SUCCESS = "SUCCESS",
    FAILED = "FAILED",
    ABANDONED = "ABANDONED",
    REFUNDED = "REFUNDED"
}
export declare enum PaymentChannel {
    MOBILE_MONEY = "MOBILE_MONEY",
    CARD = "CARD",
    BANK = "BANK",
    USSD = "USSD"
}
export declare class Payment {
    id: string;
    booking: Booking;
    bookingId: string;
    providerReference: string;
    providerId: string | null;
    status: PaymentStatus;
    amountPesewas: number;
    currency: string;
    channel: PaymentChannel | null;
    providerMeta: Record<string, any> | null;
    createdAt: Date;
    updatedAt: Date;
}
