import {
  IsString,
  IsEnum,
  IsOptional,
  IsArray,
  Matches,
  Length,
} from 'class-validator';
import { VerificationCodeType } from '../entities/verification-code.entity';

export class SendOtpDto {
  @IsEnum(VerificationCodeType)
  type: VerificationCodeType;

  @IsOptional()
  @IsString()
  @Matches(/^\+233\d{9}$/, {
    message: 'Phone must be a valid Ghanaian number (+233XXXXXXXXX)',
  })
  phone?: string;
}

export class VerifyOtpDto {
  @IsEnum(VerificationCodeType)
  type: VerificationCodeType;

  @IsString()
  @Length(6, 6)
  code: string;
}

export class CompleteProfileDto {
  @IsOptional()
  @IsString()
  university?: string;

  @IsOptional()
  @IsString()
  level?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interests?: string[];
}
