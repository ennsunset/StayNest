// src/payments/payments.dto.ts

import { IsUUID, IsOptional, IsString } from 'class-validator';

export class InitializePaymentDto {
  @IsUUID()
  bookingId: string;

  @IsOptional()
  @IsString()
  callbackUrl?: string;

  @IsOptional()
  @IsUUID()
  installmentId?: string;
}
