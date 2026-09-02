import { Controller, Get, Patch, Delete, Param, Query, UseGuards, Req } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private svc: NotificationsService) {}

  @Get()
  async list(@Req() req: any, @Query('page') page?: string) {
    return this.svc.getForUser(req.user.sub, page ? parseInt(page) : 1);
  }

  @Get('unread-count')
  async unreadCount(@Req() req: any) {
    const count = await this.svc.getUnreadCount(req.user.sub);
    return { count };
  }

  @Patch('read-all')
  async markAllRead(@Req() req: any) {
    await this.svc.markAllAsRead(req.user.sub);
    return { success: true };
  }

  @Patch(':id/read')
  async markRead(@Req() req: any, @Param('id') id: string) {
    await this.svc.markAsRead(id, req.user.sub);
    return { success: true };
  }

  @Delete(':id')
  async delete(@Req() req: any, @Param('id') id: string) {
    await this.svc.delete(id, req.user.sub);
    return { success: true };
  }
}
