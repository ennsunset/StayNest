import { UserRole } from '../users/entities/user.entity';
export declare class RegisterDto {
    fullName: string;
    email: string;
    password: string;
    role?: UserRole;
    phone?: string;
    university?: string;
    level?: string;
}
export declare class LoginDto {
    email: string;
    password: string;
}
export declare class SocialLoginDto {
    provider: 'google' | 'apple';
    idToken: string;
    fullName?: string;
}
