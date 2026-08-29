import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  UpdateDateColumn, ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Booking } from './booking.entity';

@Entity('installment_plans')
export class InstallmentPlan {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Booking, { nullable: false })
  @JoinColumn({ name: 'booking_id' })
  booking: Booking;

  @Index({ unique: true })
  @Column({ name: 'booking_id', type: 'uuid' })
  bookingId: string;

  @Column({ type: 'bigint', name: 'total_pesewas' })
  totalPesewas: number;

  @Column({ type: 'int', name: 'installment_count', default: 2 })
  installmentCount: number;

  @Column({ type: 'varchar', length: 20, default: 'ACTIVE' })
  status: string; // ACTIVE, COMPLETED, DEFAULTED

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}

@Entity('installments')
export class Installment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => InstallmentPlan, { nullable: false })
  @JoinColumn({ name: 'plan_id' })
  plan: InstallmentPlan;

  @Index()
  @Column({ name: 'plan_id', type: 'uuid' })
  planId: string;

  @Column({ type: 'int' })
  sequence: number;

  @Column({ type: 'bigint', name: 'amount_pesewas' })
  amountPesewas: number;

  @Column({ type: 'date', name: 'due_date' })
  dueDate: string;

  @Column({ type: 'varchar', length: 20, default: 'PENDING' })
  status: string; // PENDING, PAID, OVERDUE, GRACE

  @Column({ type: 'timestamptz', nullable: true, name: 'paid_at' })
  paidAt: Date | null;

  @Column({ type: 'varchar', length: 50, nullable: true, name: 'payment_reference' })
  paymentReference: string | null;

  @Column({ type: 'date', nullable: true, name: 'grace_expires_at' })
  graceExpiresAt: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}
