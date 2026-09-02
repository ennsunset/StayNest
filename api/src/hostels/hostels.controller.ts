// src/hostels/hostels.controller.ts

import {
  Controller, Get, Post, Delete, Patch, Body, Param, Query,
  UseGuards, Req, ParseUUIDPipe,
} from '@nestjs/common';
import { HostelsService } from './hostels.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/roles.guard';
import { UserRole } from '../users/entities/user.entity';
import { HostelStatus } from './entities/hostel.entity';
import { CreateHostelDto } from './hostels.dto';
import { SearchHostelsDto } from './search-hostels.dto';

@Controller('hostels')
export class HostelsController {
  constructor(private readonly hostels: HostelsService) {}

  // ── Public ────────────────────────────────────────

  @Get('featured')
  featured(@Query('university') university?: string) {
    return this.hostels.findFeatured(university);
  }

  @Get('search')
  search(@Query() dto: SearchHostelsDto) {
    return this.hostels.search(dto);
  }

  @Get('search/count')
  searchCount(@Query() dto: SearchHostelsDto) {
    return this.hostels.searchCount(dto);
  }

  @Get('amenities')
  amenities() {
    return this.hostels.findAllAmenities();
  }

  @Get('rooms/:roomId')
  roomDetail(@Param('roomId', ParseUUIDPipe) roomId: string) {
    return this.hostels.findRoomById(roomId);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.hostels.findById(id);
  }

  @Get(':id/rooms')
  rooms(@Param('id', ParseUUIDPipe) id: string) {
    return this.hostels.findRoomsByHostel(id);
  }

  // ── Owner ─────────────────────────────────────────

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.OWNER)
  @Post()
  create(@Req() req: any, @Body() dto: CreateHostelDto) {
    return this.hostels.create(req.user.sub, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.OWNER)
  @Get('owner/mine')
  myHostels(@Req() req: any) {
    return this.hostels.findAll({ ownerId: req.user.sub });
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  async softDelete(@Param('id', ParseUUIDPipe) id: string, @Req() req: any) {
    await this.hostels.softDelete(id, req.user.sub, req.user.role);
    return { message: 'Hostel moved to trash. Will be permanently deleted after 60 days.' };
  }

  @UseGuards(JwtAuthGuard)
  @Patch(':id/restore')
  async restore(@Param('id', ParseUUIDPipe) id: string, @Req() req: any) {
    await this.hostels.restore(id, req.user.sub, req.user.role);
    return { message: 'Hostel restored.' };
  }
}
