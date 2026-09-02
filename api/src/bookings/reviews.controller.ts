import {
  Controller, Post, Get, Delete, Body, Param, Req, Query, UseGuards,
} from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('reviews')
@UseGuards(JwtAuthGuard)
export class ReviewsController {
  constructor(private readonly reviews: ReviewsService) {}

  @Post(':bookingId')
  async create(
    @Req() req: any,
    @Param('bookingId') bookingId: string,
    @Body() body: { rating: number; body?: string },
  ) {
    return this.reviews.create(req.user.sub, bookingId, body);
  }

  @Get('hostel/:hostelId')
  async getForHostel(
    @Param('hostelId') hostelId: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.reviews.getForHostel(hostelId, Number(limit) || 30, Number(offset) || 0);
  }

  @Get('booking/:bookingId')
  async getForBooking(@Param('bookingId') bookingId: string) {
    const review = await this.reviews.getForBooking(bookingId);
    return { review, hasReviewed: !!review };
  }

  @Get('can-review/:hostelId')
  async canReview(
    @Param('hostelId') hostelId: string,
    @Req() req: any,
  ) {
    return this.reviews.canReview(hostelId, req.user.sub);
  }

  @Delete(':id')
  async delete(@Param('id') id: string, @Req() req: any) {
    await this.reviews.delete(id, req.user.sub);
    return { deleted: true };
  }
}
