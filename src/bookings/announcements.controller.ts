import {
  Controller, Post, Get, Delete, Body, Param, Req, Query, UseGuards,
} from '@nestjs/common';
import { AnnouncementsService } from './announcements.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('announcements')
@UseGuards(JwtAuthGuard)
export class AnnouncementsController {
  constructor(private readonly announcements: AnnouncementsService) {}

  @Post(':hostelId')
  async create(
    @Req() req: any,
    @Param('hostelId') hostelId: string,
    @Body() body: { title: string; body: string; priority?: string },
  ) {
    return this.announcements.create(req.user.sub, hostelId, body);
  }

  @Get(':hostelId')
  async getForHostel(@Param('hostelId') hostelId: string) {
    return this.announcements.getForHostel(hostelId);
  }

  @Delete(':id')
  async delete(@Req() req: any, @Param('id') id: string) {
    return this.announcements.delete(id, req.user.sub);
  }
}
