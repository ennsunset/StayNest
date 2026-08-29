import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  UpdateDateColumn, ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { User } from '../users/entities/user.entity';
import { Hostel } from '../hostels/entities/hostel.entity';

@Entity('conversations')
export class Conversation {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Hostel, { eager: false })
  @JoinColumn({ name: 'hostel_id' })
  hostel: Hostel;

  @Column({ type: 'uuid', name: 'hostel_id' })
  hostelId: string;

  @ManyToOne(() => User, { eager: false })
  @JoinColumn({ name: 'student_id' })
  student: User;

  @Column({ type: 'uuid', name: 'student_id' })
  studentId: string;

  @ManyToOne(() => User, { eager: false })
  @JoinColumn({ name: 'owner_id' })
  owner: User;

  @Column({ type: 'uuid', name: 'owner_id' })
  ownerId: string;

  @Column({ type: 'text', name: 'last_message', nullable: true })
  lastMessage: string | null;

  @Column({ type: 'timestamp', name: 'last_message_at', nullable: true })
  lastMessageAt: Date | null;

  @Column({ type: 'int', name: 'unread_student', default: 0 })
  unreadStudent: number;

  @Column({ type: 'int', name: 'unread_owner', default: 0 })
  unreadOwner: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}

@Entity('messages')
@Index(['conversationId', 'createdAt'])
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'conversation_id' })
  conversationId: string;

  @Column({ type: 'uuid', name: 'sender_id' })
  senderId: string;

  @Column({ type: 'text' })
  body: string;

  @Column({ type: 'boolean', name: 'is_read', default: false })
  isRead: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
