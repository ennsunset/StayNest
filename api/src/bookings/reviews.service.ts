import {
  Injectable, NotFoundException, BadRequestException, ForbiddenException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';

@Injectable()
export class ReviewsService {
  constructor(private readonly dataSource: DataSource) {}

  async create(studentId: string, bookingId: string, dto: { rating: number; body?: string }) {
    // Verify booking belongs to student and is COMPLETED
    const [booking] = await this.dataSource.query(
      `SELECT b.id, b.student_id, b.status, bld.hostel_id
       FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       WHERE b.id = $1`,
      [bookingId],
    );
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.student_id !== studentId) throw new ForbiddenException('Not your booking');
    if (!['CHECKED_IN', 'COMPLETED'].includes(booking.status)) {
      throw new BadRequestException('You can only review a checked-in or completed stay');
    }

    // Check not already reviewed
    const [existing] = await this.dataSource.query(
      `SELECT id FROM reviews WHERE booking_id = $1`, [bookingId],
    );
    if (existing) throw new BadRequestException('You already reviewed this stay');

    const [review] = await this.dataSource.query(
      `INSERT INTO reviews (hostel_id, student_id, booking_id, rating, body)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [booking.hostel_id, studentId, bookingId, dto.rating, dto.body || null],
    );
    return review;
  }

  async getForHostel(hostelId: string, limit = 30, offset = 0) {
    const reviews = await this.dataSource.query(
      `SELECT r.*, u.full_name AS author_name, u.avatar_url AS author_avatar
       FROM reviews r
       JOIN users u ON u.id = r.student_id
       WHERE r.hostel_id = $1 AND r.status = 'ACTIVE'
       ORDER BY r.created_at DESC LIMIT $2 OFFSET $3`,
      [hostelId, limit, offset],
    );

    const [stats] = await this.dataSource.query(
      `SELECT COUNT(*)::int AS count, COALESCE(AVG(rating), 0)::numeric(2,1) AS average
       FROM reviews WHERE hostel_id = $1 AND status = 'ACTIVE'`,
      [hostelId],
    );

    return { reviews, stats: { count: stats.count, average: parseFloat(stats.average) } };
  }

  async getForBooking(bookingId: string) {
    const [review] = await this.dataSource.query(
      `SELECT * FROM reviews WHERE booking_id = $1`, [bookingId],
    );
    return review || null;
  }

  async canReview(hostelId: string, studentId: string): Promise<{ canReview: boolean; bookingId?: string }> {
    const result = await this.dataSource.query(
      `SELECT b.id AS booking_id
       FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       LEFT JOIN reviews rv ON rv.booking_id = b.id
       WHERE bld.hostel_id = $1
         AND b.student_id = $2
         AND b.status IN ('CHECKED_IN', 'COMPLETED')
         AND rv.id IS NULL
       ORDER BY b.created_at DESC
       LIMIT 1`,
      [hostelId, studentId],
    );
    if (result.length) {
      return { canReview: true, bookingId: result[0].booking_id };
    }
    return { canReview: false };
  }

  async delete(reviewId: string, studentId: string): Promise<void> {
    const [review] = await this.dataSource.query(
      `SELECT id, student_id FROM reviews WHERE id = $1`, [reviewId],
    );
    if (!review) throw new NotFoundException('Review not found');
    if (review.student_id !== studentId) throw new ForbiddenException('Not your review');
    await this.dataSource.query(`DELETE FROM reviews WHERE id = $1`, [reviewId]);
  }
}
