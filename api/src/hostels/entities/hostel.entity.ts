// src/hostels/entities/hostel.entity.ts

import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  UpdateDateColumn, ManyToOne, OneToMany, ManyToMany, JoinTable, JoinColumn, Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

// ── Amenity ─────────────────────────────────────────

@Entity('amenities')
export class Amenity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 50 })
  name: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  icon: string | null;

  @Column({ type: 'int', default: 0, name: 'sort_order' })
  sortOrder: number;
}

// ── Hostel ──────────────────────────────────────────

export enum HostelStatus {
  DRAFT = 'DRAFT',
  PENDING_REVIEW = 'PENDING_REVIEW',
  ACTIVE = 'ACTIVE',
  REJECTED = 'REJECTED',
  SUSPENDED = 'SUSPENDED',
}

@Entity('hostels')
export class Hostel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { nullable: false })
  @JoinColumn({ name: 'owner_id' })
  owner: User;

  @Column({ name: 'owner_id', type: 'uuid' })
  ownerId: string;

  @Column({ type: 'varchar', length: 200 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ type: 'varchar', length: 500 })
  address: string;

  @Column({ type: 'varchar', length: 100 })
  city: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  region: string | null;

  @Column({ type: 'varchar', length: 200, nullable: true })
  area: string | null;

  @Column({ type: 'varchar', length: 300, nullable: true })
  landmark: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true, name: 'digital_address' })
  digitalAddress: string | null;

  @Column({ name: 'gate_opening_time', type: 'time', nullable: true })
  gateOpeningTime: string;

  @Column({ name: 'gate_closing_time', type: 'time', nullable: true })
  gateClosingTime: string;

  @Column({ name: 'check_out_time', type: 'time', nullable: true })
  checkOutTime: string;

  @Column({ name: 'cancellation_policy', default: 'FLEXIBLE' })
  cancellationPolicy: string;

  @Column({ name: 'house_rules', type: 'text', nullable: true })
  houseRules: string;

  @Column({ name: 'semester_duration_months', type: 'int', default: 4 })
  semesterDurationMonths: number;

  @Column({ name: 'grace_period_days', type: 'int', default: 5 })
  gracePeriodDays: number;

  // PostGIS point for geo queries
  @Index({ spatial: true })
  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    nullable: true,
  })
  location: string | null;

  @Column({ type: 'enum', enum: HostelStatus, default: HostelStatus.DRAFT })
  status: HostelStatus;

  @Column({ type: 'boolean', default: false })
  verified: boolean;

  @Column({ type: 'varchar', length: 50, nullable: true, name: 'gender_policy' })
  genderPolicy: string | null; // MALE_ONLY, FEMALE_ONLY, MIXED

  @ManyToMany(() => Amenity)
  @JoinTable({
    name: 'hostel_amenities',
    joinColumn: { name: 'hostel_id' },
    inverseJoinColumn: { name: 'amenity_id' },
  })
  amenities: Amenity[];

  @OneToMany(() => Building, (b) => b.hostel, { cascade: true })
  buildings: Building[];

  @Column({ type: 'varchar', length: 20, default: 'FLEXIBLE', name: 'booking_mode' })
  bookingMode: string; // SEMESTER_ONLY, YEAR_ONLY, FLEXIBLE

  @Column({ type: 'boolean', default: false, name: 'installments_enabled' })
  installmentsEnabled: boolean;

  @Column({ type: 'varchar', length: 100, nullable: true })
  university: string | null;

  @Column({ type: 'double precision', nullable: true })
  latitude: number | null;

  @Column({ type: 'double precision', nullable: true })
  longitude: number | null;

  @Column({ type: 'timestamptz', nullable: true, name: 'deleted_at' })
  deletedAt: Date | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @Column({ type: 'text', array: true, default: '{}', name: 'image_urls' })
  imageUrls: string[];

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}

// ── Building ────────────────────────────────────────

@Entity('buildings')
export class Building {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Hostel, (h) => h.buildings, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'hostel_id' })
  hostel: Hostel;

  @Column({ name: 'hostel_id', type: 'uuid' })
  hostelId: string;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @OneToMany(() => Floor, (f) => f.building, { cascade: true })
  floors: Floor[];

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;
}

// ── Floor ───────────────────────────────────────────

@Entity('floors')
export class Floor {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Building, (b) => b.floors, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'building_id' })
  building: Building;

  @Column({ name: 'building_id', type: 'uuid' })
  buildingId: string;

  @Column({ type: 'varchar', length: 50 })
  label: string; // "Ground Floor", "Floor 1"

  @Column({ type: 'int', default: 0, name: 'sort_order' })
  sortOrder: number;

  @OneToMany(() => Room, (r) => r.floor, { cascade: true })
  rooms: Room[];

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;
}

// ── Room ────────────────────────────────────────────

export enum RoomType {
  SINGLE = '1-in-a-room',
  DOUBLE = '2-in-a-room',
  TRIPLE = '3-in-a-room',
  QUAD = '4-in-a-room',
  FIVE = '5-in-a-room',
  SIX = '6-in-a-room',
  SEVEN = '7-in-a-room',
  EIGHT = '8-in-a-room',
}

@Entity('rooms')
export class Room {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Floor, (f) => f.rooms, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'floor_id' })
  floor: Floor;

  @Column({ name: 'floor_id', type: 'uuid' })
  floorId: string;

  @Column({ type: 'varchar', length: 20 })
  number: string; // "101", "104B"

  @Column({ type: 'enum', enum: RoomType })
  type: RoomType;

  // Price in pesewas (D1). Per academic year.
  @Column({ type: 'bigint', name: 'price_pesewas' })
  pricePesewas: number;

  @Column({ type: 'bigint', nullable: true, name: 'price_per_semester_pesewas' })
  pricePerSemesterPesewas: number | null;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ type: 'boolean', default: false, name: 'has_ac' })
  hasAC: boolean;

  @Column({ type: 'boolean', default: false, name: 'has_fan' })
  hasFan: boolean;

  @Column({ type: 'int', default: 1, name: 'socket_count' })
  socketCount: number;

  @Column({ type: 'boolean', default: false, name: 'has_tv' })
  hasTV: boolean;

  @Column({ type: 'boolean', default: false, name: 'has_private_bath' })
  hasPrivateBath: boolean;

  @Column({ type: 'text', array: true, default: '{}', name: 'image_urls' })
  imageUrls: string[];

  @Column({ type: 'bigint', default: 0, name: 'security_deposit_pesewas' })
  securityDepositPesewas: number;

  @OneToMany(() => Bed, (b) => b.room, { cascade: true })
  beds: Bed[];

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;
}

// ── Bed — the atomic bookable unit ──────────────────

export enum BedStatus {
  AVAILABLE = 'AVAILABLE',
  HELD = 'HELD',
  BOOKED = 'BOOKED',
  OCCUPIED = 'OCCUPIED',
  MAINTENANCE = 'MAINTENANCE',
  DISABLED = 'DISABLED',
}

@Entity('beds')
export class Bed {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Room, (r) => r.beds, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'room_id' })
  room: Room;

  @Column({ name: 'room_id', type: 'uuid' })
  roomId: string;

  @Column({ type: 'varchar', length: 20 })
  label: string; // "Bed A", "Bed 1"

  @Column({ type: 'enum', enum: BedStatus, default: BedStatus.AVAILABLE })
  status: BedStatus;

  @Column({ type: 'timestamptz', nullable: true, name: 'held_until' })
  heldUntil: Date | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}
