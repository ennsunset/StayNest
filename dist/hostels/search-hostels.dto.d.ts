import { RoomType } from './entities/hostel.entity';
export declare class SearchHostelsDto {
    university?: string;
    q?: string;
    minPrice?: number;
    maxPrice?: number;
    roomType?: RoomType;
    amenities?: string[];
    genderPolicy?: string;
    lat?: number;
    lng?: number;
    radiusKm?: number;
    sort?: 'price_asc' | 'price_desc' | 'distance' | 'newest';
    page?: number;
    limit?: number;
}
