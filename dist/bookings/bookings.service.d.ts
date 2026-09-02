import { Repository, DataSource } from 'typeorm';
import { Booking } from './entities/booking.entity';
import { InstallmentPlan, Installment } from './entities/installment.entity';
import { Bed } from '../hostels/entities/hostel.entity';
import { NotificationsService } from '../notifications/notifications.service';
export declare class BookingsService {
    private readonly bookingRepo;
    private readonly bedRepo;
    private readonly planRepo;
    private readonly installmentRepo;
    private readonly dataSource;
    private readonly notificationsService;
    private readonly logger;
    constructor(bookingRepo: Repository<Booking>, bedRepo: Repository<Bed>, planRepo: Repository<InstallmentPlan>, installmentRepo: Repository<Installment>, dataSource: DataSource, notificationsService: NotificationsService);
    holdBed(studentId: string, bedId: string, checkInDate?: string, duration?: string, paymentType?: string): Promise<Booking>;
    findById(id: string): Promise<Booking>;
    findByStudent(studentId: string): Promise<Booking[]>;
    findByReference(reference: string): Promise<Booking>;
    getAgreement(bookingId: string): Promise<{
        contractId: any;
        studentName: any;
        hostelName: any;
        property: string;
        termStart: string;
        termEnd: string;
        duration: any;
        houseRules: any;
        status: any;
        signedAt: any;
    }>;
    getRoommates(bookingId: string): Promise<any>;
    createMaintenance(bookingId: string, studentId: string, body: {
        title: string;
        description?: string;
        category?: string;
        priority?: string;
    }): Promise<any>;
    getMaintenance(bookingId: string): Promise<any>;
    checkIn(bookingId: string): Promise<{
        message: string;
        bookingId?: undefined;
    } | {
        message: string;
        bookingId: any;
    }>;
    signAgreement(bookingId: string): Promise<{
        alreadySigned: boolean;
        signedAt: any;
    }>;
    cancel(bookingId: string, studentId: string, reason?: string): Promise<Booking>;
    confirm(bookingId: string): Promise<Booking>;
    getBedsForRoom(roomId: string): Promise<any[]>;
    handleHoldExpiry(): Promise<void>;
    handleAutoCheckIn(): Promise<void>;
    private expireStaleHold;
    private expireBooking;
    private notifyBookingEvent;
    checkInstallmentEligibility(studentId: string, hostelId: string): Promise<{
        eligible: boolean;
        reason?: string;
    }>;
    createInstallmentPlan(bookingId: string): Promise<{
        plan: any;
        installments: any[];
    }>;
    getInstallmentPlan(bookingId: string): Promise<{
        plan: any;
        installments: any[];
    } | null>;
    payInstallment(installmentId: string, paymentReference: string): Promise<any>;
    handleInstallmentOverdue(): Promise<void>;
    private generateReference;
    private rowToBooking;
    getRefund(bookingId: string, studentId: string): Promise<{
        id: any;
        bookingId: any;
        reference: any;
        hostelName: any;
        amountPesewas: number;
        status: any;
        reason: any;
        rejectReason: any;
        approvedAt: any;
        refundedAt: any;
        createdAt: any;
        updatedAt: any;
    } | null>;
    approveRefund(refundId: string, approve: boolean, rejectReason?: string): Promise<any>;
    seedMoveInTasks(bookingId: string): Promise<void>;
    getMoveInTasks(bookingId: string, userId: string): Promise<any[]>;
    updateMoveInTask(taskId: string, userId: string, status: string): Promise<any>;
    seedUtilityAccounts(bookingId: string): Promise<void>;
    getUtilityData(bookingId: string, userId: string): Promise<any>;
    addCustomTask(bookingId: string, userId: string, title: string, description?: string): Promise<any>;
    deleteCustomTask(taskId: string, userId: string): Promise<void>;
    ownerUpdateTask(taskId: string, ownerId: string, status: string): Promise<any>;
    updateCheckInDate(bookingId: string, userId: string, checkInDate: string): Promise<any>;
}
