// src/hostels/hostels.dto.ts

import { IsString, IsOptional, IsNumber, MinLength } from 'class-validator';

export class CreateHostelDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsString()
  address: string;

  @IsString()
  city: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  genderPolicy?: string;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;
}
