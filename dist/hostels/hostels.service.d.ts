import { DataSource } from 'typeorm';
import { Repository } from 'typeorm';
import { Hostel, HostelStatus, Room, Bed, Amenity } from './entities/hostel.entity';
import { SearchHostelsDto } from './search-hostels.dto';
export declare class HostelsService {
    private readonly hostelRepo;
    private readonly roomRepo;
    private readonly bedRepo;
    private readonly amenityRepo;
    private readonly dataSource;
    constructor(hostelRepo: Repository<Hostel>, roomRepo: Repository<Room>, bedRepo: Repository<Bed>, amenityRepo: Repository<Amenity>, dataSource: DataSource);
    private buildSearchWhere;
    search(dto: SearchHostelsDto): Promise<{
        data: any[];
        total: number;
        page: number;
        limit: number;
    }>;
    searchCount(dto: SearchHostelsDto): Promise<{
        count: number;
    }>;
    create(ownerId: string, data: {
        name: string;
        address: string;
        city: string;
        description?: string;
        genderPolicy?: string;
        latitude?: number;
        longitude?: number;
    }): Promise<Hostel>;
    findAll(options?: {
        status?: HostelStatus;
        ownerId?: string;
        page?: number;
        limit?: number;
    }): Promise<{
        data: Hostel[];
        total: number;
    }>;
    findById(id: string): Promise<Hostel>;
    softDelete(hostelId: string, userId: string, role: string): Promise<void>;
    restore(hostelId: string, userId: string, role: string): Promise<void>;
    purgeDeletedHostels(): Promise<void>;
    findFeatured(university?: string): Promise<any[]>;
    findRoomsByHostel(hostelId: string): Promise<Room[]>;
    findRoomById(id: string): Promise<Room>;
    findBedsByRoom(roomId: string): Promise<Bed[]>;
    findAllAmenities(): Promise<Amenity[]>;
    verifyOwnership(hostelId: string, ownerId: string): Promise<Hostel>;
}
