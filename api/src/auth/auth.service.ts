// src/auth/auth.service.ts

import { Injectable, BadRequestException, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { User, UserRole } from '../users/entities/user.entity';
import { VerificationCode, VerificationCodeType } from './entities/verification-code.entity';
import { SendOtpDto, VerifyOtpDto, CompleteProfileDto } from './dto/auth-flow.dto';
import { OAuth2Client } from 'google-auth-library';
import { SmsService } from '../common/services/sms.service';
import { EmailService } from '../common/services/email.service';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    @InjectRepository(VerificationCode)
    private readonly codesRepo: Repository<VerificationCode>,
    private readonly sms: SmsService,
    private readonly email: EmailService,
  ) {}

  async register(data: {
    fullName: string;
    email: string;
    password: string;
    role?: UserRole;
    phone?: string;
    university?: string;
    level?: string;
  }): Promise<{ user: Partial<User>; tokens: TokenPair }> {
    const user = await this.users.create(data);
    const tokens = await this.generateTokens(user);
    return { user: this.sanitize(user), tokens };
  }

  async login(
    email: string,
    password: string,
  ): Promise<{ user: Partial<User>; tokens: TokenPair }> {
    const user = await this.users.findByEmail(email);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const valid = await this.users.validatePassword(user, password);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const tokens = await this.generateTokens(user);
    return { user: this.sanitize(user), tokens };
  }

  async refresh(userId: string): Promise<TokenPair> {
    const user = await this.users.findById(userId);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('User not found or inactive');
    }
    return this.generateTokens(user);
  }

  async sendOtp(userId: string, dto: SendOtpDto): Promise<{ message: string }> {
    const user = await this.users.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    if (dto.type === VerificationCodeType.PHONE && dto.phone) {
      await this.users.updatePhone(userId, dto.phone);
    }
    await this.codesRepo.update(
      { userId, type: dto.type, used: false },
      { used: true },
    );
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const verificationCode = this.codesRepo.create({
      userId,
      code,
      type: dto.type,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    });
    await this.codesRepo.save(verificationCode);
    if (dto.type === VerificationCodeType.PHONE) {
      const phone = dto.phone || user.phone;
      if (phone) await this.sms.send(phone, 'Your StayNest code is: ' + code);
    } else {
      await this.email.send(user.email, 'StayNest Verification Code',
        '<h2>Your verification code</h2><p style="font-size:32px;font-weight:bold;letter-spacing:8px">' + code + '</p><p>Expires in 5 minutes.</p>');
    }
    console.log('[OTP] Code for ' + user.email + ': ' + code);
    return { message: 'Verification code sent via ' + dto.type.toLowerCase() };
  }

  async verifyOtp(userId: string, dto: VerifyOtpDto): Promise<{ verified: boolean }> {
    const found = await this.codesRepo.findOne({
      where: { userId, type: dto.type, code: dto.code, used: false },
      order: { createdAt: 'DESC' },
    });
    if (!found) {
      throw new UnauthorizedException('Invalid verification code');
    }
    if (new Date() > found.expiresAt) {
      throw new UnauthorizedException('Verification code has expired');
    }
    found.used = true;
    await this.codesRepo.save(found);
    if (dto.type === VerificationCodeType.PHONE) {
      await this.users.markPhoneVerified(userId);
    } else {
      await this.users.markEmailVerified(userId);
    }
    return { verified: true };
  }

  async completeProfile(userId: string, dto: CompleteProfileDto): Promise<User> {
    return this.users.completeProfile(userId, dto);
  }

  async getVerificationStatus(userId: string) {
    const user = await this.users.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return {
      phoneVerified: user.phoneVerified,
      emailVerified: user.emailVerified,
      profileCompleted: user.profileCompleted,
      phone: user.phone,
      email: user.email,
    };
  }

  private async generateTokens(user: User): Promise<TokenPair> {
    const payload: JwtPayload = { sub: user.id, email: user.email, role: user.role };
    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync(payload),
      this.jwt.signAsync(payload, {
        expiresIn: this.config.get<string>('JWT_REFRESH_EXPIRES_IN', '7d') as any,
      }),
    ]);
    return { accessToken, refreshToken };
  }

  private sanitize(user: User): Partial<User> {
    const { passwordHash, ...rest } = user;
    return rest;
  }

  async socialLogin(provider: 'google' | 'apple', idToken: string, fullName?: string): Promise<{ user: Partial<User>; tokens: TokenPair }> {
    let email: string;
    let name: string;

    if (provider === 'google') {
      const clientId = this.config.get<string>('GOOGLE_CLIENT_ID', '');
      const client = new OAuth2Client(clientId);
      try {
        const ticket = await client.verifyIdToken({ idToken, audience: clientId });
        const payload = ticket.getPayload();
        if (!payload || !payload.email) throw new UnauthorizedException('Invalid Google token');
        email = payload.email;
        name = payload.name || email.split('@')[0];
      } catch (e) {
        throw new UnauthorizedException('Google token verification failed');
      }
    } else if (provider === 'apple') {
      try {
        const parts = idToken.split('.');
        const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
        if (!payload.email) throw new UnauthorizedException('Invalid Apple token');
        email = payload.email;
        name = fullName || email.split('@')[0];
      } catch (e) {
        throw new UnauthorizedException('Apple token verification failed');
      }
    } else {
      throw new BadRequestException('Unsupported provider');
    }

    let user = await this.users.findByEmail(email);
    if (!user) {
      user = await this.users.createSocialUser({ fullName: name, email, provider });
    }
    if (!user!.isActive) throw new UnauthorizedException('Account is disabled');

    const tokens = await this.generateTokens(user!);
    return { user: this.sanitize(user!), tokens };
  }

  async forgotPassword(email: string) {
    const user = await this.users.findByEmail(email);
    if (!user) return { message: 'If that email is registered, a reset code has been sent.' };

    await this.codesRepo.update(
      { userId: user.id, type: VerificationCodeType.PASSWORD_RESET, used: false },
      { used: true },
    );

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const vc = this.codesRepo.create({
      userId: user.id,
      code,
      type: VerificationCodeType.PASSWORD_RESET,
      expiresAt: new Date(Date.now() + 15 * 60 * 1000),
    });
    await this.codesRepo.save(vc);

    await this.email.send(email, 'StayNest Password Reset',
      '<h2>Password Reset Code</h2><p style="font-size:32px;font-weight:bold;letter-spacing:8px">' + code + '</p><p>Expires in 15 minutes.</p>');
    console.log('[RESET] Code for ' + email + ': ' + code);

    return { message: 'If that email is registered, a reset code has been sent.' };
  }

  async getMe(userId: string) {
    const user = await this.users.findById(userId) as any;
    return { id: user.id, fullName: user.fullName, email: user.email, phone: user.phone, role: user.role, university: user.university, level: user.level, avatarUrl: user.avatarUrl, emailVerified: user.emailVerified, phoneVerified: user.phoneVerified, idVerified: user.idVerified, profileCompleted: user.profileCompleted, interests: user.interests };
  }

  async updateProfile(userId: string, data: { fullName?: string; phone?: string; level?: string; university?: string; avatarUrl?: string }) {
    return this.users.updateProfile(userId, data);
  }

  async resetPassword(email: string, code: string, newPassword: string) {
    const user = await this.users.findByEmail(email);
    if (!user) throw new BadRequestException('Invalid code');

    const vc = await this.codesRepo.findOne({
      where: {
        userId: user.id,
        code,
        type: VerificationCodeType.PASSWORD_RESET,
        used: false,
      },
      order: { createdAt: 'DESC' },
    });

    if (!vc || vc.expiresAt < new Date()) {
      throw new BadRequestException('Invalid or expired code');
    }

    vc.used = true;
    await this.codesRepo.save(vc);
    await this.users.updatePassword(user.id, newPassword);

    return { message: 'Password reset successfully' };
  }
}
