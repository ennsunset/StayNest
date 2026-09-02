import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum UtilityType {
  ELECTRICITY = 'ELECTRICITY',
  WATER = 'WATER',
  INTERNET = 'INTERNET',
}

export enum BillStatus {
  PENDING = 'PENDING',
  SETTLED = 'SETTLED',
  OVERDUE = 'OVERDUE',
}

@Entity('utility_accounts')
export class UtilityAccount {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'booking_id' })
  bookingId: string;

  @Column({ type: 'varchar', length: 20, name: 'utility_type' })
  utilityType: UtilityType;

  @Column({ type: 'bigint', name: 'credit_pesewas', default: 0 })
  creditPesewas: number;

  @Column({ type: 'int', name: 'estimated_days_left', default: 0 })
  estimatedDaysLeft: number;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}

@Entity('utility_bills')
export class UtilityBill {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'account_id' })
  accountId: string;

  @Column({ type: 'varchar', length: 100 })
  label: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'varchar', length: 20, name: 'utility_type' })
  utilityType: UtilityType;

  @Column({ type: 'bigint', name: 'amount_pesewas' })
  amountPesewas: number;

  @Column({ type: 'varchar', length: 20, default: BillStatus.PENDING })
  status: BillStatus;

  @Column({ type: 'varchar', length: 50, nullable: true, name: 'billing_period' })
  billingPeriod: string;

  @Column({ type: 'timestamptz', nullable: true, name: 'due_date' })
  dueDate: Date | null;

  @Column({ type: 'timestamptz', nullable: true, name: 'paid_at' })
  paidAt: Date | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}
