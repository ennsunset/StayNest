import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { User, UserRole } from '../users/entities/user.entity';
import { VerificationCode } from './entities/verification-code.entity';
import { SendOtpDto, VerifyOtpDto, CompleteProfileDto } from './dto/auth-flow.dto';
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
export declare class AuthService {
    private readonly users;
    private readonly jwt;
    private readonly config;
    private readonly codesRepo;
    private readonly sms;
    private readonly email;
    constructor(users: UsersService, jwt: JwtService, config: ConfigService, codesRepo: Repository<VerificationCode>, sms: SmsService, email: EmailService);
    register(data: {
        fullName: string;
        email: string;
        password: string;
        role?: UserRole;
        phone?: string;
        university?: string;
        level?: string;
    }): Promise<{
        user: Partial<User>;
        tokens: TokenPair;
    }>;
    login(email: string, password: string): Promise<{
        user: Partial<User>;
        tokens: TokenPair;
    }>;
    refresh(userId: string): Promise<TokenPair>;
    sendOtp(userId: string, dto: SendOtpDto): Promise<{
        message: string;
    }>;
    verifyOtp(userId: string, dto: VerifyOtpDto): Promise<{
        verified: boolean;
    }>;
    completeProfile(userId: string, dto: CompleteProfileDto): Promise<User>;
    getVerificationStatus(userId: string): Promise<{
        phoneVerified: boolean;
        emailVerified: boolean;
        profileCompleted: boolean;
        phone: string | null;
        email: string;
    }>;
    private generateTokens;
    private sanitize;
    socialLogin(provider: 'google' | 'apple', idToken: string, fullName?: string): Promise<{
        user: Partial<User>;
        tokens: TokenPair;
    }>;
    forgotPassword(email: string): Promise<{
        message: string;
    }>;
    getMe(userId: string): Promise<{
        id: any;
        fullName: any;
        email: any;
        phone: any;
        role: any;
        university: any;
        level: any;
        avatarUrl: any;
        emailVerified: any;
        phoneVerified: any;
        idVerified: any;
        profileCompleted: any;
        interests: any;
    }>;
    updateProfile(userId: string, data: {
        fullName?: string;
        phone?: string;
        level?: string;
        university?: string;
        avatarUrl?: string;
    }): Promise<any>;
    resetPassword(email: string, code: string, newPassword: string): Promise<{
        message: string;
    }>;
}
