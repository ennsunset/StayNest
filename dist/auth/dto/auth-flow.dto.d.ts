import { VerificationCodeType } from '../entities/verification-code.entity';
export declare class SendOtpDto {
    type: VerificationCodeType;
    phone?: string;
}
export declare class VerifyOtpDto {
    type: VerificationCodeType;
    code: string;
}
export declare class CompleteProfileDto {
    university?: string;
    level?: string;
    interests?: string[];
}
