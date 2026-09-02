"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Bed = exports.BedStatus = exports.Room = exports.RoomType = exports.Floor = exports.Building = exports.Hostel = exports.HostelStatus = exports.Amenity = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../../users/entities/user.entity");
let Amenity = class Amenity {
};
exports.Amenity = Amenity;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Amenity.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Index)({ unique: true }),
    (0, typeorm_1.Column)({ type: 'varchar', length: 50 }),
    __metadata("design:type", String)
], Amenity.prototype, "name", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 50, nullable: true }),
    __metadata("design:type", Object)
], Amenity.prototype, "icon", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 0, name: 'sort_order' }),
    __metadata("design:type", Number)
], Amenity.prototype, "sortOrder", void 0);
exports.Amenity = Amenity = __decorate([
    (0, typeorm_1.Entity)('amenities')
], Amenity);
var HostelStatus;
(function (HostelStatus) {
    HostelStatus["DRAFT"] = "DRAFT";
    HostelStatus["PENDING_REVIEW"] = "PENDING_REVIEW";
    HostelStatus["ACTIVE"] = "ACTIVE";
    HostelStatus["REJECTED"] = "REJECTED";
    HostelStatus["SUSPENDED"] = "SUSPENDED";
})(HostelStatus || (exports.HostelStatus = HostelStatus = {}));
let Hostel = class Hostel {
};
exports.Hostel = Hostel;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Hostel.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, { nullable: false }),
    (0, typeorm_1.JoinColumn)({ name: 'owner_id' }),
    __metadata("design:type", user_entity_1.User)
], Hostel.prototype, "owner", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'owner_id', type: 'uuid' }),
    __metadata("design:type", String)
], Hostel.prototype, "ownerId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 200 }),
    __metadata("design:type", String)
], Hostel.prototype, "name", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", Object)
], Hostel.prototype, "description", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 500 }),
    __metadata("design:type", String)
], Hostel.prototype, "address", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 100 }),
    __metadata("design:type", String)
], Hostel.prototype, "city", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 100, nullable: true }),
    __metadata("design:type", Object)
], Hostel.prototype, "region", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 200, nullable: true }),
    __metadata("design:type", Object)
], Hostel.prototype, "area", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 300, nullable: true }),
    __metadata("design:type", Object)
], Hostel.prototype, "landmark", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 50, nullable: true, name: 'digital_address' }),
    __metadata("design:type", Object)
], Hostel.prototype, "digitalAddress", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'gate_opening_time', type: 'time', nullable: true }),
    __metadata("design:type", String)
], Hostel.prototype, "gateOpeningTime", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'gate_closing_time', type: 'time', nullable: true }),
    __metadata("design:type", String)
], Hostel.prototype, "gateClosingTime", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'check_out_time', type: 'time', nullable: true }),
    __metadata("design:type", String)
], Hostel.prototype, "checkOutTime", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'cancellation_policy', default: 'FLEXIBLE' }),
    __metadata("design:type", String)
], Hostel.prototype, "cancellationPolicy", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'house_rules', type: 'text', nullable: true }),
    __metadata("design:type", String)
], Hostel.prototype, "houseRules", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'semester_duration_months', type: 'int', default: 4 }),
    __metadata("design:type", Number)
], Hostel.prototype, "semesterDurationMonths", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'grace_period_days', type: 'int', default: 5 }),
    __metadata("design:type", Number)
], Hostel.prototype, "gracePeriodDays", void 0);
__decorate([
    (0, typeorm_1.Index)({ spatial: true }),
    (0, typeorm_1.Column)({
        type: 'geography',
        spatialFeatureType: 'Point',
        srid: 4326,
        nullable: true,
    }),
    __metadata("design:type", Object)
], Hostel.prototype, "location", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'enum', enum: HostelStatus, default: HostelStatus.DRAFT }),
    __metadata("design:type", String)
], Hostel.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false }),
    __metadata("design:type", Boolean)
], Hostel.prototype, "verified", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 50, nullable: true, name: 'gender_policy' }),
    __metadata("design:type", Object)
], Hostel.prototype, "genderPolicy", void 0);
__decorate([
    (0, typeorm_1.ManyToMany)(() => Amenity),
    (0, typeorm_1.JoinTable)({
        name: 'hostel_amenities',
        joinColumn: { name: 'hostel_id' },
        inverseJoinColumn: { name: 'amenity_id' },
    }),
    __metadata("design:type", Array)
], Hostel.prototype, "amenities", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => Building, (b) => b.hostel, { cascade: true }),
    __metadata("design:type", Array)
], Hostel.prototype, "buildings", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20, default: 'FLEXIBLE', name: 'booking_mode' }),
    __metadata("design:type", String)
], Hostel.prototype, "bookingMode", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false, name: 'installments_enabled' }),
    __metadata("design:type", Boolean)
], Hostel.prototype, "installmentsEnabled", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 100, nullable: true }),
    __metadata("design:type", Object)
], Hostel.prototype, "university", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'double precision', nullable: true }),
    __metadata("design:type", Object)
], Hostel.prototype, "latitude", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'double precision', nullable: true }),
    __metadata("design:type", Object)
], Hostel.prototype, "longitude", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamptz', nullable: true, name: 'deleted_at' }),
    __metadata("design:type", Object)
], Hostel.prototype, "deletedAt", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], Hostel.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', array: true, default: '{}', name: 'image_urls' }),
    __metadata("design:type", Array)
], Hostel.prototype, "imageUrls", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ type: 'timestamptz', name: 'updated_at' }),
    __metadata("design:type", Date)
], Hostel.prototype, "updatedAt", void 0);
exports.Hostel = Hostel = __decorate([
    (0, typeorm_1.Entity)('hostels')
], Hostel);
let Building = class Building {
};
exports.Building = Building;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Building.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => Hostel, (h) => h.buildings, { onDelete: 'CASCADE' }),
    (0, typeorm_1.JoinColumn)({ name: 'hostel_id' }),
    __metadata("design:type", Hostel)
], Building.prototype, "hostel", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'hostel_id', type: 'uuid' }),
    __metadata("design:type", String)
], Building.prototype, "hostelId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 100 }),
    __metadata("design:type", String)
], Building.prototype, "name", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => Floor, (f) => f.building, { cascade: true }),
    __metadata("design:type", Array)
], Building.prototype, "floors", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], Building.prototype, "createdAt", void 0);
exports.Building = Building = __decorate([
    (0, typeorm_1.Entity)('buildings')
], Building);
let Floor = class Floor {
};
exports.Floor = Floor;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Floor.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => Building, (b) => b.floors, { onDelete: 'CASCADE' }),
    (0, typeorm_1.JoinColumn)({ name: 'building_id' }),
    __metadata("design:type", Building)
], Floor.prototype, "building", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'building_id', type: 'uuid' }),
    __metadata("design:type", String)
], Floor.prototype, "buildingId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 50 }),
    __metadata("design:type", String)
], Floor.prototype, "label", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 0, name: 'sort_order' }),
    __metadata("design:type", Number)
], Floor.prototype, "sortOrder", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => Room, (r) => r.floor, { cascade: true }),
    __metadata("design:type", Array)
], Floor.prototype, "rooms", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], Floor.prototype, "createdAt", void 0);
exports.Floor = Floor = __decorate([
    (0, typeorm_1.Entity)('floors')
], Floor);
var RoomType;
(function (RoomType) {
    RoomType["SINGLE"] = "1-in-a-room";
    RoomType["DOUBLE"] = "2-in-a-room";
    RoomType["TRIPLE"] = "3-in-a-room";
    RoomType["QUAD"] = "4-in-a-room";
    RoomType["FIVE"] = "5-in-a-room";
    RoomType["SIX"] = "6-in-a-room";
    RoomType["SEVEN"] = "7-in-a-room";
    RoomType["EIGHT"] = "8-in-a-room";
})(RoomType || (exports.RoomType = RoomType = {}));
let Room = class Room {
};
exports.Room = Room;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Room.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => Floor, (f) => f.rooms, { onDelete: 'CASCADE' }),
    (0, typeorm_1.JoinColumn)({ name: 'floor_id' }),
    __metadata("design:type", Floor)
], Room.prototype, "floor", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'floor_id', type: 'uuid' }),
    __metadata("design:type", String)
], Room.prototype, "floorId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20 }),
    __metadata("design:type", String)
], Room.prototype, "number", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'enum', enum: RoomType }),
    __metadata("design:type", String)
], Room.prototype, "type", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', name: 'price_pesewas' }),
    __metadata("design:type", Number)
], Room.prototype, "pricePesewas", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', nullable: true, name: 'price_per_semester_pesewas' }),
    __metadata("design:type", Object)
], Room.prototype, "pricePerSemesterPesewas", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", Object)
], Room.prototype, "description", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false, name: 'has_ac' }),
    __metadata("design:type", Boolean)
], Room.prototype, "hasAC", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false, name: 'has_fan' }),
    __metadata("design:type", Boolean)
], Room.prototype, "hasFan", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 1, name: 'socket_count' }),
    __metadata("design:type", Number)
], Room.prototype, "socketCount", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false, name: 'has_tv' }),
    __metadata("design:type", Boolean)
], Room.prototype, "hasTV", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false, name: 'has_private_bath' }),
    __metadata("design:type", Boolean)
], Room.prototype, "hasPrivateBath", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', array: true, default: '{}', name: 'image_urls' }),
    __metadata("design:type", Array)
], Room.prototype, "imageUrls", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'bigint', default: 0, name: 'security_deposit_pesewas' }),
    __metadata("design:type", Number)
], Room.prototype, "securityDepositPesewas", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => Bed, (b) => b.room, { cascade: true }),
    __metadata("design:type", Array)
], Room.prototype, "beds", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], Room.prototype, "createdAt", void 0);
exports.Room = Room = __decorate([
    (0, typeorm_1.Entity)('rooms')
], Room);
var BedStatus;
(function (BedStatus) {
    BedStatus["AVAILABLE"] = "AVAILABLE";
    BedStatus["HELD"] = "HELD";
    BedStatus["BOOKED"] = "BOOKED";
    BedStatus["OCCUPIED"] = "OCCUPIED";
    BedStatus["MAINTENANCE"] = "MAINTENANCE";
    BedStatus["DISABLED"] = "DISABLED";
})(BedStatus || (exports.BedStatus = BedStatus = {}));
let Bed = class Bed {
};
exports.Bed = Bed;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Bed.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => Room, (r) => r.beds, { onDelete: 'CASCADE' }),
    (0, typeorm_1.JoinColumn)({ name: 'room_id' }),
    __metadata("design:type", Room)
], Bed.prototype, "room", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'room_id', type: 'uuid' }),
    __metadata("design:type", String)
], Bed.prototype, "roomId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 20 }),
    __metadata("design:type", String)
], Bed.prototype, "label", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'enum', enum: BedStatus, default: BedStatus.AVAILABLE }),
    __metadata("design:type", String)
], Bed.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamptz', nullable: true, name: 'held_until' }),
    __metadata("design:type", Object)
], Bed.prototype, "heldUntil", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz', name: 'created_at' }),
    __metadata("design:type", Date)
], Bed.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ type: 'timestamptz', name: 'updated_at' }),
    __metadata("design:type", Date)
], Bed.prototype, "updatedAt", void 0);
exports.Bed = Bed = __decorate([
    (0, typeorm_1.Entity)('beds')
], Bed);
//# sourceMappingURL=hostel.entity.js.map