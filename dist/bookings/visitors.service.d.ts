import { DataSource } from 'typeorm';
export declare class VisitorsService {
    private readonly dataSource;
    private readonly logger;
    constructor(dataSource: DataSource);
    createPass(studentId: string, bookingId: string, dto: {
        visitorName: string;
        visitorPhone?: string;
        purpose?: string;
    }): Promise<any>;
    getPassesForBooking(bookingId: string, studentId: string): Promise<any>;
    getPassesForHostel(hostelId: string): Promise<any>;
    verifyPass(qrToken: string): Promise<{
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
    revokePass(passId: string, studentId: string): Promise<{
        success: boolean;
    }>;
    deletePass(passId: string, studentId: string): Promise<{
        success: boolean;
    }>;
    handleExpireOldPasses(): Promise<void>;
}
