// src/hostels/hostels.module.ts

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Hostel, Building, Floor, Room, Bed, Amenity } from './entities/hostel.entity';
import { HostelsService } from './hostels.service';
import { HostelsController } from './hostels.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Hostel, Building, Floor, Room, Bed, Amenity])],
  providers: [HostelsService],
  controllers: [HostelsController],
  exports: [HostelsService],
})
export class HostelsModule {}
