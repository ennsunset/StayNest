import { AuthService } from './auth.service';
import { RegisterDto, LoginDto, SocialLoginDto } from './auth.dto';
import { SendOtpDto, VerifyOtpDto, CompleteProfileDto } from './dto/auth-flow.dto';
export declare class AuthController {
    private readonly auth;
    constructor(auth: AuthService);
    register(dto: RegisterDto): Promise<{
        user: Partial<import("../users/entities/user.entity").User>;
        tokens: import("./auth.service").TokenPair;
    }>;
    login(dto: LoginDto): Promise<{
        user: Partial<import("../users/entities/user.entity").User>;
        tokens: import("./auth.service").TokenPair;
    }>;
    socialLogin(dto: SocialLoginDto): Promise<{
        user: Partial<import("../users/entities/user.entity").User>;
        tokens: import("./auth.service").TokenPair;
    }>;
    refresh(req: any): Promise<import("./auth.service").TokenPair>;
    me(req: any): Promise<{
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
    sendOtp(req: any, dto: SendOtpDto): Promise<{
        message: string;
    }>;
    verifyOtp(req: any, dto: VerifyOtpDto): Promise<{
        verified: boolean;
    }>;
    completeProfile(req: any, dto: CompleteProfileDto): Promise<import("../users/entities/user.entity").User>;
    getVerificationStatus(req: any): Promise<{
        phoneVerified: boolean;
        emailVerified: boolean;
        profileCompleted: boolean;
        phone: string | null;
        email: string;
    }>;
    updateProfile(req: any, body: {
        fullName?: string;
        phone?: string;
        avatarUrl?: string;
    }): Promise<any>;
    forgotPassword(body: {
        email: string;
    }): Promise<{
        message: string;
    }>;
    resetPassword(body: {
        email: string;
        code: string;
        newPassword: string;
    }): Promise<{
        message: string;
    }>;
}
