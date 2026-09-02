import { Repository, DataSource } from 'typeorm';
import { Payment } from './entities/payment.entity';
import { Booking } from '../bookings/entities/booking.entity';
import { BookingsService } from '../bookings/bookings.service';
import { PaystackProvider } from './paystack.provider';
export declare class PaymentsService {
    private readonly paymentRepo;
    private readonly bookingRepo;
    private readonly dataSource;
    private readonly paystack;
    private readonly bookingsService;
    private readonly logger;
    constructor(paymentRepo: Repository<Payment>, bookingRepo: Repository<Booking>, dataSource: DataSource, paystack: PaystackProvider, bookingsService: BookingsService);
    initializePayment(bookingId: string, studentId: string, email: string, callbackUrl?: string, installmentId?: string): Promise<{
        paymentId: string;
        authorizationUrl: string;
        accessCode: string;
        reference: string;
    }>;
    handleWebhook(event: string, data: any): Promise<void>;
    verifyPayment(reference: string): Promise<Payment | null>;
    getStudentHistory(studentId: string): Promise<{
        totalPaidYearPesewas: number;
        payments: any;
    }>;
    private mapChannel;
}
