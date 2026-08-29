import {
  Controller, Post, Get, Patch, Delete, Body, Param, Req, Query,
  UseGuards,
} from '@nestjs/common';
import { CommunityService } from './community.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('community')
@UseGuards(JwtAuthGuard)
export class CommunityController {
  constructor(private readonly community: CommunityService) {}

  @Post(':hostelId/posts')
  async createPost(
    @Req() req: any,
    @Param('hostelId') hostelId: string,
    @Body() body: { category: string; title: string; body: string; imageUrl?: string; pricePesewas?: number },
  ) {
    return this.community.createPost(req.user.sub, hostelId, body);
  }

  @Get(':hostelId/posts')
  async getPosts(
    @Param('hostelId') hostelId: string,
    @Query('category') category?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.community.getPosts(hostelId, category, Number(limit) || 50, Number(offset) || 0);
  }

  @Patch('posts/:postId/sold')
  async markSold(@Req() req: any, @Param('postId') postId: string) {
    return this.community.markSold(postId, req.user.sub);
  }

  @Delete('posts/:postId')
  async deletePost(@Req() req: any, @Param('postId') postId: string) {
    return this.community.deletePost(postId, req.user.sub);
  }
}
