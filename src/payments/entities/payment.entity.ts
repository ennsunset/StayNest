import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  UpdateDateColumn, ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Booking } from '../../bookings/entities/booking.entity';

export enum PaymentStatus {
  PENDING = 'PENDING',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
  ABANDONED = 'ABANDONED',
  REFUNDED = 'REFUNDED',
}

export enum PaymentChannel {
  MOBILE_MONEY = 'MOBILE_MONEY',
  CARD = 'CARD',
  BANK = 'BANK',
  USSD = 'USSD',
}

@Entity('payments')
export class Payment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Booking, { nullable: false })
  @JoinColumn({ name: 'booking_id' })
  booking: Booking;

  @Index()
  @Column({ name: 'booking_id', type: 'uuid' })
  bookingId: string;

  @Index({ unique: true })
  @Column({ name: 'provider_reference', type: 'varchar', length: 100 })
  providerReference: string;

  @Column({ name: 'provider_id', type: 'varchar', length: 100, nullable: true })
  providerId: string | null;

  @Column({ type: 'enum', enum: PaymentStatus, default: PaymentStatus.PENDING })
  status: PaymentStatus;

  @Column({ type: 'bigint', name: 'amount_pesewas' })
  amountPesewas: number;

  @Column({ type: 'varchar', length: 3, default: 'GHS' })
  currency: string;

  @Column({ type: 'enum', enum: PaymentChannel, nullable: true })
  channel: PaymentChannel | null;

  @Column({ type: 'jsonb', nullable: true, name: 'provider_meta' })
  providerMeta: Record<string, any> | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}
