import { DataSource } from 'typeorm';
export declare class OwnerService {
    private readonly ds;
    constructor(ds: DataSource);
    private _safeInt;
    getHostels(ownerId: string): Promise<{
        data: any;
    }>;
    private _verifyOwnership;
    getDashboard(ownerId: string): Promise<{
        occupancy: {
            rate: number;
            totalBeds: number;
            occupiedBeds: number;
            availableBeds: number;
            maintenanceBeds: number;
        };
        revenue: {
            totalPesewas: number;
            commissionPesewas: number;
            netPesewas: number;
            thisMonthPesewas: number;
        };
        pendingRequests: number;
        maintenanceRequests: number;
        activeHostels: number;
    }>;
    getBookings(ownerId: string, opts: {
        status?: string;
        page: number;
        limit: number;
    }): Promise<{
        data: any;
        total: number;
        page: number;
        limit: number;
    }>;
    acceptBooking(ownerId: string, bookingId: string): Promise<{
        message: string;
        bookingId: string;
        status: string;
    }>;
    declineBooking(ownerId: string, bookingId: string, reason: string): Promise<{
        message: string;
        bookingId: string;
        status: string;
    }>;
    getTenants(ownerId: string): Promise<any>;
    getPayments(ownerId: string, opts: {
        page: number;
        limit: number;
    }): Promise<{
        summary: {
            settledPesewas: number;
            pendingPesewas: number;
            thisMonthPesewas: number;
            commissionPesewas: number;
        };
        data: any;
        total: number;
        page: number;
        limit: number;
    }>;
    private bedCountFromType;
    createRoom(ownerId: string, hostelId: string, dto: {
        floorId: string;
        number: string;
        type: string;
        pricePesewas: number;
        pricePerSemesterPesewas?: number;
        hasAC?: boolean;
        hasPrivateBath?: boolean;
        description?: string;
        bedCount?: number;
        hasFan?: boolean;
        socketCount?: number;
        hasTV?: boolean;
    }): Promise<any>;
    addBeds(ownerId: string, roomId: string, count: number): Promise<{
        added: number;
        beds: any[];
    }>;
    updateBedStatus(ownerId: string, bedId: string, status: string): Promise<{
        id: string;
        status: string;
    }>;
    getRoomsForHostel(ownerId: string, hostelId: string): Promise<{
        data: any;
    }>;
    getBedsForRoom(ownerId: string, roomId: string): Promise<{
        roomNumber: any;
        roomType: any;
        maxBeds: number;
        beds: any;
    }>;
    getFloorsForHostel(ownerId: string, hostelId: string): Promise<{
        data: any;
    }>;
    updateRoom(ownerId: string, roomId: string, dto: {
        type?: string;
        pricePesewas?: number;
        pricePerSemesterPesewas?: number;
        hasAC?: boolean;
        hasFan?: boolean;
        hasPrivateBath?: boolean;
        hasTV?: boolean;
        socketCount?: number;
    }): Promise<{
        updated: boolean;
    }>;
    checkoutBed(ownerId: string, bedId: string): Promise<{
        id: string;
        status: string;
    }>;
    deleteBed(ownerId: string, bedId: string): Promise<{
        deleted: boolean;
    }>;
    createHostel(ownerId: string, body: any): Promise<{
        id: any;
        name: any;
        status: any;
    }>;
    submitHostel(ownerId: string, hostelId: string): Promise<{
        id: string;
        status: string;
    }>;
    getHostel(ownerId: string, hostelId: string): Promise<any>;
    updateHostel(ownerId: string, hostelId: string, body: any): Promise<{
        id: string;
        updated: boolean;
    }>;
}
