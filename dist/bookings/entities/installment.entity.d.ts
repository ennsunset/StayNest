import { Booking } from './booking.entity';
export declare class InstallmentPlan {
    id: string;
    booking: Booking;
    bookingId: string;
    totalPesewas: number;
    installmentCount: number;
    status: string;
    createdAt: Date;
    updatedAt: Date;
}
export declare class Installment {
    id: string;
    plan: InstallmentPlan;
    planId: string;
    sequence: number;
    amountPesewas: number;
    dueDate: string;
    status: string;
    paidAt: Date | null;
    paymentReference: string | null;
    graceExpiresAt: string | null;
    createdAt: Date;
    updatedAt: Date;
}
