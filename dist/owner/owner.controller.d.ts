import { OwnerService } from './owner.service';
export declare class OwnerController {
    private readonly ownerService;
    constructor(ownerService: OwnerService);
    getHostels(req: any): Promise<{
        data: any;
    }>;
    getDashboard(req: any): Promise<{
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
    getBookings(req: any, status?: string, page?: string, limit?: string): Promise<{
        data: any;
        total: number;
        page: number;
        limit: number;
    }>;
    acceptBooking(req: any, bookingId: string): Promise<{
        message: string;
        bookingId: string;
        status: string;
    }>;
    declineBooking(req: any, bookingId: string, reason: string): Promise<{
        message: string;
        bookingId: string;
        status: string;
    }>;
    getTenants(req: any): Promise<any>;
    getPayments(req: any, page?: string, limit?: string): Promise<{
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
    getRooms(req: any, hostelId: string): Promise<{
        data: any;
    }>;
    getFloors(req: any, hostelId: string): Promise<{
        data: any;
    }>;
    createRoom(req: any, hostelId: string, dto: {
        floorId: string;
        number: string;
        type: string;
        pricePesewas: number;
        pricePerSemesterPesewas?: number;
        hasAC?: boolean;
        hasPrivateBath?: boolean;
        description?: string;
        bedCount?: number;
    }): Promise<any>;
    updateRoom(req: any, roomId: string, dto: any): Promise<{
        updated: boolean;
    }>;
    getBeds(req: any, roomId: string): Promise<{
        roomNumber: any;
        roomType: any;
        maxBeds: number;
        beds: any;
    }>;
    addBeds(req: any, roomId: string, count: number): Promise<{
        added: number;
        beds: any[];
    }>;
    updateBedStatus(req: any, bedId: string, status: string): Promise<{
        id: string;
        status: string;
    }>;
    checkoutBed(req: any, bedId: string): Promise<{
        id: string;
        status: string;
    }>;
    deleteBed(req: any, bedId: string): Promise<{
        deleted: boolean;
    }>;
    createHostel(req: any, body: any): Promise<{
        id: any;
        name: any;
        status: any;
    }>;
    submitHostel(req: any, hostelId: string): Promise<{
        id: string;
        status: string;
    }>;
    getHostel(req: any, hostelId: string): Promise<any>;
    updateHostel(req: any, hostelId: string, body: any): Promise<{
        id: string;
        updated: boolean;
    }>;
}
