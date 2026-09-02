import {
  Injectable, NotFoundException, ForbiddenException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class AnnouncementsService {
  constructor(private readonly dataSource: DataSource, private readonly notifications: NotificationsService) {}

  async create(ownerId: string, hostelId: string, dto: { title: string; body: string; priority?: string }) {
    // Verify owner owns this hostel
    const [hostel] = await this.dataSource.query(
      `SELECT id FROM hostels WHERE id = $1 AND owner_id = $2`, [hostelId, ownerId],
    );
    if (!hostel) throw new ForbiddenException('Not your hostel');

    const [ann] = await this.dataSource.query(
      `INSERT INTO announcements (hostel_id, owner_id, title, body, priority)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [hostelId, ownerId, dto.title, dto.body, dto.priority || 'NORMAL'],
    );
    // Notify all checked-in students
    this.notifyResidents(hostelId, ann).catch(() => {});

    return ann;
  }

  private async notifyResidents(hostelId: string, ann: any) {
    const residents = await this.dataSource.query(
      `SELECT DISTINCT b.student_id FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       WHERE bld.hostel_id = $1 AND b.status = 'CHECKED_IN'`,
      [hostelId],
    );
    for (const r of residents) {
      await this.notifications.create({
        userId: r.student_id,
        type: 'ANNOUNCEMENT',
        title: ann.priority === 'URGENT' ? ann.title : ann.title,
        body: ann.body.length > 100 ? ann.body.substring(0, 100) + '...' : ann.body,
        data: { announcementId: ann.id, hostelId },
      }).catch(() => {});
    }
  }

  async getForHostel(hostelId: string, limit = 30) {
    return this.dataSource.query(
      `SELECT a.*, u.full_name AS author_name
       FROM announcements a
       JOIN users u ON u.id = a.owner_id
       WHERE a.hostel_id = $1 AND a.status = 'ACTIVE'
       ORDER BY a.created_at DESC LIMIT $2`,
      [hostelId, limit],
    );
  }

  async delete(announcementId: string, ownerId: string) {
    const [ann] = await this.dataSource.query(
      `SELECT * FROM announcements WHERE id = $1`, [announcementId],
    );
    if (!ann) throw new NotFoundException('Announcement not found');
    if (ann.owner_id !== ownerId) throw new ForbiddenException('Not your announcement');

    await this.dataSource.query(
      `UPDATE announcements SET status = 'DELETED', updated_at = NOW() WHERE id = $1`, [announcementId],
    );
    return { success: true };
  }
}
