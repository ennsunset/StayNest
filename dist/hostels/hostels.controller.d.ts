import { HostelsService } from './hostels.service';
import { CreateHostelDto } from './hostels.dto';
import { SearchHostelsDto } from './search-hostels.dto';
export declare class HostelsController {
    private readonly hostels;
    constructor(hostels: HostelsService);
    featured(university?: string): Promise<any[]>;
    search(dto: SearchHostelsDto): Promise<{
        data: any[];
        total: number;
        page: number;
        limit: number;
    }>;
    searchCount(dto: SearchHostelsDto): Promise<{
        count: number;
    }>;
    amenities(): Promise<import("./entities/hostel.entity").Amenity[]>;
    roomDetail(roomId: string): Promise<import("./entities/hostel.entity").Room>;
    findOne(id: string): Promise<import("./entities/hostel.entity").Hostel>;
    rooms(id: string): Promise<import("./entities/hostel.entity").Room[]>;
    create(req: any, dto: CreateHostelDto): Promise<import("./entities/hostel.entity").Hostel>;
    myHostels(req: any): Promise<{
        data: import("./entities/hostel.entity").Hostel[];
        total: number;
    }>;
    softDelete(id: string, req: any): Promise<{
        message: string;
    }>;
    restore(id: string, req: any): Promise<{
        message: string;
    }>;
}
