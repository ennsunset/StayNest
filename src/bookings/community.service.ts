import {
  Injectable, NotFoundException, BadRequestException, ForbiddenException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';

@Injectable()
export class CommunityService {
  constructor(private readonly dataSource: DataSource) {}

  async createPost(studentId: string, hostelId: string, dto: {
    category: string;
    title: string;
    body: string;
    imageUrl?: string;
    pricePesewas?: number;
  }) {
    // Verify student is checked in at this hostel
    const [booking] = await this.dataSource.query(
      `SELECT b.id FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       WHERE b.student_id = $1 AND bld.hostel_id = $2 AND b.status = 'CHECKED_IN'
       LIMIT 1`,
      [studentId, hostelId],
    );
    if (!booking) throw new ForbiddenException('You must be a current resident to post');

    const [post] = await this.dataSource.query(
      `INSERT INTO community_posts (hostel_id, student_id, category, title, body, image_url, price_pesewas)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [hostelId, studentId, dto.category, dto.title, dto.body, dto.imageUrl || null, dto.pricePesewas || null],
    );
    return post;
  }

  async getPosts(hostelId: string, category?: string, limit = 50, offset = 0) {
    let query = `SELECT cp.*, u.full_name AS author_name, u.avatar_url AS author_avatar
       FROM community_posts cp
       JOIN users u ON u.id = cp.student_id
       WHERE cp.hostel_id = $1 AND cp.status = 'ACTIVE'`;
    const params: any[] = [hostelId];

    if (category && category !== 'ALL') {
      params.push(category);
      query += ` AND cp.category = $${params.length}`;
    }

    params.push(limit, offset);
    query += ` ORDER BY cp.created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`;

    return this.dataSource.query(query, params);
  }

  async deletePost(postId: string, studentId: string) {
    const [post] = await this.dataSource.query(
      `SELECT * FROM community_posts WHERE id = $1`,
      [postId],
    );
    if (!post) throw new NotFoundException('Post not found');
    if (post.student_id !== studentId) throw new ForbiddenException('Not your post');

    await this.dataSource.query(
      `UPDATE community_posts SET status = 'DELETED', updated_at = NOW() WHERE id = $1`,
      [postId],
    );
    return { success: true };
  }

  async markSold(postId: string, studentId: string) {
    const [post] = await this.dataSource.query(
      `SELECT * FROM community_posts WHERE id = $1`,
      [postId],
    );
    if (!post) throw new NotFoundException('Post not found');
    if (post.student_id !== studentId) throw new ForbiddenException('Not your post');

    await this.dataSource.query(
      `UPDATE community_posts SET status = 'SOLD', updated_at = NOW() WHERE id = $1`,
      [postId],
    );
    return { success: true };
  }
}
