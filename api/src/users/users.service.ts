// src/users/users.service.ts

import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as argon2 from 'argon2';
import { User, UserRole } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}

  async findByEmail(email: string): Promise<User | null> {
    return this.repo.findOne({ where: { email: email.toLowerCase() } });
  }

  async findById(id: string): Promise<User | null> {
    return this.repo.findOne({ where: { id } });
  }

  async create(data: {
    fullName: string;
    email: string;
    password: string;
    role?: UserRole;
    phone?: string;
    university?: string;
    level?: string;
  }): Promise<User> {
    const existing = await this.findByEmail(data.email);
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await argon2.hash(data.password, {
      type: argon2.argon2id,
    });

    const user = this.repo.create({
      fullName: data.fullName,
      email: data.email.toLowerCase(),
      passwordHash,
      role: data.role ?? UserRole.STUDENT,
      phone: data.phone ?? null,
      university: data.university ?? null,
      level: data.level ?? null,
    });

    return this.repo.save(user);
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    return argon2.verify(user.passwordHash, password);
  }

  async updatePhone(userId: string, phone: string): Promise<void> {
    await this.repo.update(userId, { phone });
  }

  async markPhoneVerified(userId: string): Promise<void> {
    await this.repo.update(userId, { phoneVerified: true });
  }

  async markEmailVerified(userId: string): Promise<void> {
    await this.repo.update(userId, { emailVerified: true });
  }

  async completeProfile(
    userId: string,
    dto: { university?: string; level?: string; interests?: string[] },
  ): Promise<User> {
    await this.repo.update(userId, {
      ...dto,
      profileCompleted: true,
    });
    return this.findById(userId) as Promise<User>;
  }

  async updatePassword(userId: string, newPassword: string): Promise<void> {
    const passwordHash = await argon2.hash(newPassword, {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 4,
    });
    await this.repo.update(userId, { passwordHash });
  }

  async updateProfile(userId: string, data: { fullName?: string; phone?: string; level?: string; university?: string; avatarUrl?: string }): Promise<any> {
    const user = await this.repo.findOneBy({ id: userId });
    if (!user) throw new Error('User not found');
    if (data.fullName) user.fullName = data.fullName;
    if (data.phone) user.phone = data.phone;
    if (data.level) user.level = data.level;
    if (data.university) user.university = data.university;
    if (data.avatarUrl) user.avatarUrl = data.avatarUrl;
    await this.repo.save(user);
    return { id: user.id, fullName: user.fullName, email: user.email, phone: user.phone, role: user.role, university: user.university, level: user.level, avatarUrl: user.avatarUrl, emailVerified: user.emailVerified, phoneVerified: user.phoneVerified, idVerified: user.idVerified, profileCompleted: user.profileCompleted, interests: user.interests };
  }

  async createSocialUser(data: {
    fullName: string;
    email: string;
    provider: string;
  }): Promise<User> {
    const user = this.repo.create({
      fullName: data.fullName,
      email: data.email.toLowerCase(),
      passwordHash: 'SOCIAL_' + data.provider.toUpperCase(),
      role: UserRole.STUDENT,
      emailVerified: true,
      isActive: true,
    });
    return this.repo.save(user);
  }
}
