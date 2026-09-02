import {
  IsOptional, IsString, IsNumber, IsEnum, IsArray,
  IsUUID, Min, Max,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { RoomType } from './entities/hostel.entity';

export class SearchHostelsDto {
  /** University filter (school-first feed) */
  @IsOptional()
  @IsString()
  university?: string;

  /** Full-text search query (matches name, description, address, city) */
  @IsOptional()
  @IsString()
  q?: string;

  /** Minimum room price in pesewas */
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  minPrice?: number;

  /** Maximum room price in pesewas */
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  maxPrice?: number;

  /** Room type filter (e.g. "1-in-a-room") */
  @IsOptional()
  @IsEnum(RoomType)
  roomType?: RoomType;

  /** Amenity IDs to require (all must match) */
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  @Transform(({ value }) =>
    typeof value === 'string' ? value.split(',') : value,
  )
  amenities?: string[];

  /** Gender policy: MALE_ONLY, FEMALE_ONLY, MIXED */
  @IsOptional()
  @IsString()
  genderPolicy?: string;

  /** Latitude for distance filter */
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lat?: number;

  /** Longitude for distance filter */
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lng?: number;

  /** Radius in km (default 5, max 50) */
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.1)
  @Max(50)
  radiusKm?: number;

  /** Sort: price_asc, price_desc, distance, newest */
  @IsOptional()
  @IsString()
  sort?: 'price_asc' | 'price_desc' | 'distance' | 'newest';

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(100)
  limit?: number;
}
