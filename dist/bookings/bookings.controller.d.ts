import { BookingsService } from './bookings.service';
import { VisitorsService } from './visitors.service';
import { CreateBookingDto, CancelBookingDto } from './bookings.dto';
export declare class BookingsController {
    private readonly bookings;
    private readonly visitors;
    constructor(bookings: BookingsService, visitors: VisitorsService);
    getRefund(id: string, req: any): Promise<{
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
    hold(req: any, dto: CreateBookingDto): Promise<import("./entities/booking.entity").Booking>;
    myBookings(req: any): Promise<import("./entities/booking.entity").Booking[]>;
    findOne(id: string): Promise<import("./entities/booking.entity").Booking>;
    findByRef(reference: string): Promise<import("./entities/booking.entity").Booking>;
    getAgreement(id: string): Promise<{
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
    getRoommates(id: string): Promise<any>;
    createMaintenance(id: string, req: any, body: {
        title: string;
        description?: string;
        category?: string;
        priority?: string;
    }): Promise<any>;
    getMaintenance(id: string): Promise<any>;
    checkIn(id: string): Promise<{
        message: string;
        bookingId?: undefined;
    } | {
        message: string;
        bookingId: any;
    }>;
    signAgreement(id: string): Promise<{
        alreadySigned: boolean;
        signedAt: any;
    }>;
    cancel(id: string, req: any, dto: CancelBookingDto): Promise<import("./entities/booking.entity").Booking>;
    confirm(id: string): Promise<import("./entities/booking.entity").Booking>;
    checkInstallmentEligibility(req: any, hostelId: string): Promise<{
        eligible: boolean;
        reason?: string;
    }>;
    getInstallmentPlan(id: string): Promise<{
        plan: any;
        installments: any[];
    }>;
    payInstallment(installmentId: string, body: {
        paymentReference: string;
    }): Promise<any>;
    verifyVisitorPass(token: string): Promise<{
        valid: boolean;
        reason: string;
        pass?: undefined;
        message?: undefined;
    } | {
        valid: boolean;
        reason: string;
        pass: any;
        message?: undefined;
    } | {
        valid: boolean;
        pass: any;
        message: string;
        reason?: undefined;
    }>;
    deleteVisitorPass(req: any, passId: string): Promise<{
        success: boolean;
    }>;
    revokeVisitorPass(req: any, passId: string): Promise<{
        success: boolean;
    }>;
    createVisitorPass(req: any, bookingId: string, body: {
        visitorName: string;
        visitorPhone?: string;
        purpose?: string;
    }): Promise<any>;
    getVisitorPasses(req: any, bookingId: string): Promise<any>;
    getMoveInTasks(bookingId: string, req: any): Promise<any[]>;
    updateMoveInTask(taskId: string, status: string, req: any): Promise<any>;
    getUtilities(bookingId: string, req: any): Promise<any>;
    addCustomTask(bookingId: string, title: string, description: string, req: any): Promise<any>;
    deleteCustomTask(taskId: string, req: any): Promise<void>;
    updateCheckInDate(bookingId: string, checkInDate: string, req: any): Promise<any>;
    ownerUpdateTask(taskId: string, status: string, req: any): Promise<any>;
}
