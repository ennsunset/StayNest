// src/bookings/bookings.dto.ts

import { IsUUID, IsOptional, IsString, IsIn } from 'class-validator';

/** POST /bookings — hold a bed */
export class CreateBookingDto {
  @IsUUID()
  bedId: string;

  @IsOptional()
  @IsString()
  checkInDate?: string; // ISO date string, e.g. '2026-09-01'

  @IsOptional()
  @IsIn(['FULL_YEAR', 'SEMESTER_1', 'SEMESTER_2'])
  duration?: string; // defaults to FULL_YEAR

  @IsOptional()
  @IsIn(['FULL', 'INSTALLMENT'])
  paymentType?: string; // defaults to FULL
}

/** PATCH /bookings/:id/cancel */
export class CancelBookingDto {
  @IsOptional()
  @IsString()
  reason?: string;
}
