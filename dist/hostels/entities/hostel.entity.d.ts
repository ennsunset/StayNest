import { User } from '../../users/entities/user.entity';
export declare class Amenity {
    id: string;
    name: string;
    icon: string | null;
    sortOrder: number;
}
export declare enum HostelStatus {
    DRAFT = "DRAFT",
    PENDING_REVIEW = "PENDING_REVIEW",
    ACTIVE = "ACTIVE",
    REJECTED = "REJECTED",
    SUSPENDED = "SUSPENDED"
}
export declare class Hostel {
    id: string;
    owner: User;
    ownerId: string;
    name: string;
    description: string | null;
    address: string;
    city: string;
    region: string | null;
    area: string | null;
    landmark: string | null;
    digitalAddress: string | null;
    gateOpeningTime: string;
    gateClosingTime: string;
    checkOutTime: string;
    cancellationPolicy: string;
    houseRules: string;
    semesterDurationMonths: number;
    gracePeriodDays: number;
    location: string | null;
    status: HostelStatus;
    verified: boolean;
    genderPolicy: string | null;
    amenities: Amenity[];
    buildings: Building[];
    bookingMode: string;
    installmentsEnabled: boolean;
    university: string | null;
    latitude: number | null;
    longitude: number | null;
    deletedAt: Date | null;
    createdAt: Date;
    imageUrls: string[];
    updatedAt: Date;
}
export declare class Building {
    id: string;
    hostel: Hostel;
    hostelId: string;
    name: string;
    floors: Floor[];
    createdAt: Date;
}
export declare class Floor {
    id: string;
    building: Building;
    buildingId: string;
    label: string;
    sortOrder: number;
    rooms: Room[];
    createdAt: Date;
}
export declare enum RoomType {
    SINGLE = "1-in-a-room",
    DOUBLE = "2-in-a-room",
    TRIPLE = "3-in-a-room",
    QUAD = "4-in-a-room",
    FIVE = "5-in-a-room",
    SIX = "6-in-a-room",
    SEVEN = "7-in-a-room",
    EIGHT = "8-in-a-room"
}
export declare class Room {
    id: string;
    floor: Floor;
    floorId: string;
    number: string;
    type: RoomType;
    pricePesewas: number;
    pricePerSemesterPesewas: number | null;
    description: string | null;
    hasAC: boolean;
    hasFan: boolean;
    socketCount: number;
    hasTV: boolean;
    hasPrivateBath: boolean;
    imageUrls: string[];
    securityDepositPesewas: number;
    beds: Bed[];
    createdAt: Date;
}
export declare enum BedStatus {
    AVAILABLE = "AVAILABLE",
    HELD = "HELD",
    BOOKED = "BOOKED",
    OCCUPIED = "OCCUPIED",
    MAINTENANCE = "MAINTENANCE",
    DISABLED = "DISABLED"
}
export declare class Bed {
    id: string;
    room: Room;
    roomId: string;
    label: string;
    status: BedStatus;
    heldUntil: Date | null;
    createdAt: Date;
    updatedAt: Date;
}
