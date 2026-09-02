import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { MessagingService } from './messaging.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('messaging')
@UseGuards(JwtAuthGuard)
export class MessagingController {
  constructor(private readonly messagingService: MessagingService) {}

  @Post('conversations')
  async getOrCreate(@Req() req: any, @Body() body: { hostelId: string; ownerId: string }) {
    return this.messagingService.getOrCreateConversation(req.user.sub, body.hostelId, body.ownerId);
  }

  @Post('conversations/direct')
  createDM(@Req() req: any, @Body() body: { peerId: string }) {
    return this.messagingService.getOrCreateDM(req.user.sub, body.peerId);
  }

  @Get('conversations')
  async listConversations(@Req() req: any, @Query('role') role?: string) {
    const userRole = role === 'OWNER' ? 'OWNER' : 'STUDENT';
    return this.messagingService.getConversationsForUser(req.user.sub, userRole as any);
  }

  @Get('conversations/:id/messages')
  async getMessages(
    @Req() req: any,
    @Param('id') id: string,
    @Query('page') page?: string,
  ) {
    return this.messagingService.getMessages(id, req.user.sub, parseInt(page || '1', 10));
  }

  @Post('conversations/:id/messages')
  async sendMessage(
    @Req() req: any,
    @Param('id') id: string,
    @Body() body: { body: string },
  ) {
    return this.messagingService.sendMessage(id, req.user.sub, body.body);
  }

  @Delete('conversations/:id')
  async deleteConversation(@Req() req: any, @Param('id') id: string) {
    await this.messagingService.deleteConversation(id, req.user.sub);
    return { deleted: true };
  }
}
