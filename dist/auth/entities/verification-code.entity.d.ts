import { User } from '../../users/entities/user.entity';
export declare enum VerificationCodeType {
    PHONE = "PHONE",
    EMAIL = "EMAIL",
    PASSWORD_RESET = "PASSWORD_RESET"
}
export declare class VerificationCode {
    id: string;
    userId: string;
    user: User;
    code: string;
    type: VerificationCodeType;
    expiresAt: Date;
    used: boolean;
    createdAt: Date;
}
