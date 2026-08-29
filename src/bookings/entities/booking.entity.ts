// src/bookings/entities/booking.entity.ts

import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  UpdateDateColumn, ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Bed } from '../../hostels/entities/hostel.entity';

export enum BookingStatus {
  HELD = 'HELD',
  PENDING_PAYMENT = 'PENDING_PAYMENT',
  CONFIRMED = 'CONFIRMED',
  CHECKED_IN = 'CHECKED_IN',
  COMPLETED = 'COMPLETED',
  EXPIRED = 'EXPIRED',
  CANCELLED = 'CANCELLED',
  REFUNDED = 'REFUNDED',
}

/** Statuses that occupy a bed — only one booking per bed in these states */
export const ACTIVE_BOOKING_STATUSES: BookingStatus[] = [
  BookingStatus.HELD,
  BookingStatus.PENDING_PAYMENT,
  BookingStatus.CONFIRMED,
  BookingStatus.CHECKED_IN,
];

@Entity('bookings')
export class Booking {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { nullable: false })
  @JoinColumn({ name: 'student_id' })
  student: User;

  @Index()
  @Column({ name: 'student_id', type: 'uuid' })
  studentId: string;

  @ManyToOne(() => Bed, { nullable: false })
  @JoinColumn({ name: 'bed_id' })
  bed: Bed;

  @Index()
  @Column({ name: 'bed_id', type: 'uuid' })
  bedId: string;

  @Column({ type: 'enum', enum: BookingStatus, default: BookingStatus.HELD })
  status: BookingStatus;

  /** Server-generated booking reference: STN-YYYYMMDD-XXXX */
  @Index({ unique: true })
  @Column({ type: 'varchar', length: 20, name: 'reference' })
  reference: string;

  /** Room price snapshot at booking time, in pesewas (D1) */
  @Column({ type: 'bigint', name: 'price_pesewas' })
  pricePesewas: number;

  /** Platform fee snapshot, in pesewas */
  @Column({ type: 'bigint', name: 'platform_fee_pesewas', default: 0 })
  platformFeePesewas: number;

  /** Total = price + platform fee, in pesewas */
  @Column({ type: 'bigint', name: 'total_pesewas' })
  totalPesewas: number;

  /** When the HELD status expires — drives the countdown timer */
  @Column({ type: 'timestamptz', nullable: true, name: 'held_until' })
  heldUntil: Date | null;

  /** FULL_YEAR, SEMESTER_1, SEMESTER_2 */
  @Column({ type: 'varchar', length: 20, default: 'FULL_YEAR' })
  duration: string;

  /** Academic year or semester label */
  @Column({ type: 'varchar', length: 50, name: 'period_label', default: 'Full Academic Year' })
  periodLabel: string;

  /** Check-in date */
  @Column({ type: 'date', nullable: true, name: 'check_in_date' })
  checkInDate: string | null;

  /** Cancellation reason (if cancelled) */
  @Column({ type: 'text', nullable: true, name: 'cancel_reason' })
  cancelReason: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @Column({ type: 'timestamptz', name: 'agreement_signed_at', nullable: true })
  agreementSignedAt: Date;

  @Column({ type: 'varchar', length: 20, default: 'FULL', name: 'payment_type' })
  paymentType: string;
}
