// src/hostels/hostels.service.ts

import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DataSource } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import {
  Hostel, HostelStatus, Building, Floor, Room, Bed, Amenity,
} from './entities/hostel.entity';
import { SearchHostelsDto } from './search-hostels.dto';

@Injectable()
export class HostelsService {
  constructor(
    @InjectRepository(Hostel) private readonly hostelRepo: Repository<Hostel>,
    @InjectRepository(Room) private readonly roomRepo: Repository<Room>,
    @InjectRepository(Bed) private readonly bedRepo: Repository<Bed>,
    @InjectRepository(Amenity) private readonly amenityRepo: Repository<Amenity>,
    private readonly dataSource: DataSource,
  ) {}

  // ── Search (Stage 2) ─────────────────────────────

  /**
   * Builds WHERE clause + params for search. Used by search() and searchCount().
   */
  private buildSearchWhere(dto: SearchHostelsDto): { wheres: string[]; params: any[]; pi: number } {
    const params: any[] = [];
    const wheres: string[] = ["h.status = 'ACTIVE'", "h.deleted_at IS NULL"];
    let pi = 0;
    const p = () => `$${++pi}`;

    // Full-text search
    if (dto.q?.trim()) {
      const tsQuery = dto.q.trim().split(/\s+/).map(w => w + ':*').join(' & ');
      wheres.push(`h.search_vector @@ to_tsquery(${p()})`);
      params.push(tsQuery);
    }

    // Gender policy
    if (dto.genderPolicy) {
      wheres.push(`h.gender_policy = ${p()}`);
      params.push(dto.genderPolicy);
    }

    // University filter (school-first feed)
    if (dto.university) {
      wheres.push(`h.university = ${p()}`);
      params.push(dto.university);
    }

    // Amenity filter — hostel must have ALL requested amenities
    if (dto.amenities?.length) {
      wheres.push(
        `h.id IN (SELECT ha.hostel_id FROM hostel_amenities ha WHERE ha.amenity_id = ANY(${p()}) GROUP BY ha.hostel_id HAVING COUNT(DISTINCT ha.amenity_id) = ${dto.amenities.length})`,
      );
      params.push(dto.amenities);
    }

    // Price range / room type — hostel has at least one matching room
    if (dto.minPrice != null || dto.maxPrice != null || dto.roomType) {
      const roomWheres: string[] = [];
      if (dto.minPrice != null) {
        roomWheres.push(`r_sub.price_pesewas >= ${p()}`);
        params.push(dto.minPrice);
      }
      if (dto.maxPrice != null) {
        roomWheres.push(`r_sub.price_pesewas <= ${p()}`);
        params.push(dto.maxPrice);
      }
      if (dto.roomType) {
        roomWheres.push(`r_sub.type = ${p()}`);
        params.push(dto.roomType);
      }
      wheres.push(
        `EXISTS (SELECT 1 FROM rooms r_sub JOIN floors f_sub ON f_sub.id = r_sub.floor_id JOIN buildings b_sub ON b_sub.id = f_sub.building_id WHERE b_sub.hostel_id = h.id AND ${roomWheres.join(' AND ')})`,
      );
    }

    // Geo distance (ST_DWithin)
    if (dto.lat != null && dto.lng != null) {
      const radiusMetres = (dto.radiusKm ?? 5) * 1000;
      wheres.push(`ST_DWithin(h.location, ST_SetSRID(ST_MakePoint(${p()}, ${p()}), 4326)::geography, ${p()})`);
      params.push(dto.lng, dto.lat, radiusMetres);
    }

    return { wheres, params, pi };
  }

  /**
   * Full search — raw SQL to avoid TypeORM orderBy limitations with getManyAndCount.
   */
  async search(dto: SearchHostelsDto): Promise<{
    data: any[];
    total: number;
    page: number;
    limit: number;
  }> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 50;
    const offset = (page - 1) * limit;

    const { wheres, params: whereParams } = this.buildSearchWhere(dto);
    const whereClause = wheres.join(' AND ');

    // ── Count (uses only WHERE params) ──
    const [{ count: totalStr }] = await this.hostelRepo.query(
      `SELECT COUNT(*)::int AS count FROM hostels h WHERE ${whereClause}`,
      [...whereParams],
    );
    const total = parseInt(totalStr, 10);

    if (total === 0) {
      return { data: [], total: 0, page, limit };
    }

    // ── Build SELECT with extra columns ──
    // Start a fresh param list so indices are clean
    const { wheres: w2, params: selectParams, pi: lastPi } = this.buildSearchWhere(dto);
    const selectWhereClause = w2.join(' AND ');
    let nextPi = lastPi;
    const sp = () => `$${++nextPi}`;

    // Distance column (only when geo params present)
    let distanceCol = 'NULL::int AS distance_m';
    if (dto.lat != null && dto.lng != null) {
      distanceCol = `ST_Distance(h.location, ST_SetSRID(ST_MakePoint(${sp()}, ${sp()}), 4326)::geography)::int AS distance_m`;
      selectParams.push(dto.lng, dto.lat);
    }

    // Sorting
    let orderBy = 'h.created_at DESC';
    if (dto.sort === 'price_asc' || dto.sort === 'price_desc') {
      orderBy = `min_price ${dto.sort === 'price_asc' ? 'ASC' : 'DESC'} NULLS LAST`;
    } else if (dto.sort === 'distance' && dto.lat != null && dto.lng != null) {
      orderBy = 'distance_m ASC NULLS LAST';
    } else if (dto.q?.trim()) {
      const tsQuery = dto.q.trim().split(/\s+/).map(w => w + ':*').join(' & ');
      orderBy = `ts_rank(h.search_vector, to_tsquery(${sp()})) DESC`;
      selectParams.push(tsQuery);
    }

    // Pagination params
    selectParams.push(limit, offset);
    const limitParam = `$${nextPi + 1}`;
    const offsetParam = `$${nextPi + 2}`;

    const sql = `
      SELECT h.id, h.name, h.description, h.address, h.city, h.status, h.verified,
             h.gender_policy, h.image_urls, h.gate_opening_time, h.gate_closing_time, h.cancellation_policy, h.house_rules, h.latitude, h.longitude, h.created_at, h.updated_at,
             (SELECT MIN(r.price_pesewas)::bigint
              FROM rooms r JOIN floors f ON f.id = r.floor_id
              JOIN buildings b ON b.id = f.building_id
              WHERE b.hostel_id = h.id) AS min_price,
             (SELECT COUNT(*)::int
              FROM beds bd JOIN rooms r ON r.id = bd.room_id
              JOIN floors f ON f.id = r.floor_id
              JOIN buildings b ON b.id = f.building_id
              WHERE b.hostel_id = h.id AND bd.status = 'AVAILABLE') AS available_beds,
             ${distanceCol}
      FROM hostels h
      WHERE ${selectWhereClause}
      ORDER BY ${orderBy}
      LIMIT ${limitParam} OFFSET ${offsetParam}
    `;

    const rows = await this.hostelRepo.query(sql, selectParams);

    // Attach amenities per hostel
    const data = await Promise.all(
      rows.map(async (row: any) => {
        const amenities = await this.hostelRepo.query(
          `SELECT a.id, a.name, a.icon
           FROM amenities a
           JOIN hostel_amenities ha ON ha.amenity_id = a.id
           WHERE ha.hostel_id = $1
           ORDER BY a.sort_order`,
          [row.id],
        );
        return {
          id: row.id,
          name: row.name,
          description: row.description,
          address: row.address,
          city: row.city,
          status: row.status,
          verified: row.verified,
          genderPolicy: row.gender_policy,
          latitude: row.latitude ?? null,
          longitude: row.longitude ?? null,
          gateOpeningTime: row.gate_opening_time ?? null,
          gateClosingTime: row.gate_closing_time ?? null,
          cancellationPolicy: row.cancellation_policy ?? 'FLEXIBLE',
          houseRules: (() => { try { return row.house_rules ? JSON.parse(row.house_rules) : null; } catch(_) { return row.house_rules; } })(),
          imageUrls: row.image_urls ?? [],
          amenities,
          fromPricePesewas: parseInt(row.min_price ?? '0', 10),
          availableBeds: row.available_beds ?? 0,
          distanceMetres: row.distance_m ?? null,
          createdAt: row.created_at,
          updatedAt: row.updated_at,
        };
      }),
    );

    return { data, total, page, limit };
  }

  /**
   * Count only — for the live "Show N Results" button on Advanced Filters.
   */
  async searchCount(dto: SearchHostelsDto): Promise<{ count: number }> {
    const { wheres, params } = this.buildSearchWhere(dto);
    const whereClause = wheres.join(' AND ');
    const [{ count: totalStr }] = await this.hostelRepo.query(
      `SELECT COUNT(*)::int AS count FROM hostels h WHERE ${whereClause}`,
      params,
    );
    return { count: parseInt(totalStr, 10) };
  }

  // ── Hostels (existing) ────────────────────────────

  async create(ownerId: string, data: {
    name: string;
    address: string;
    city: string;
    description?: string;
    genderPolicy?: string;
    latitude?: number;
    longitude?: number;
  }): Promise<Hostel> {
    const hostel = this.hostelRepo.create({
      ownerId,
      name: data.name,
      address: data.address,
      city: data.city,
      description: data.description ?? null,
      genderPolicy: data.genderPolicy ?? null,
      status: HostelStatus.PENDING_REVIEW,
    });

    return await this.hostelRepo.save(hostel);
  }

  async findAll(options?: {
    status?: HostelStatus;
    ownerId?: string;
    page?: number;
    limit?: number;
  }): Promise<{ data: Hostel[]; total: number }> {
    const page = options?.page ?? 1;
    const limit = options?.limit ?? 20;

    const qb = this.hostelRepo
      .createQueryBuilder('h')
      .leftJoinAndSelect('h.amenities', 'a')
      .orderBy('h.createdAt', 'DESC');

    if (options?.status) {
      qb.andWhere('h.status = :status', { status: options.status });
    }
    if (options?.ownerId) {
      qb.andWhere('h.ownerId = :ownerId', { ownerId: options.ownerId });
    }

    const [data, total] = await qb
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { data, total };
  }

  async findById(id: string): Promise<Hostel> {
    const hostel = await this.hostelRepo.findOne({
      where: { id },
      relations: ['amenities', 'buildings', 'buildings.floors', 'buildings.floors.rooms', 'buildings.floors.rooms.beds'],
    });
    if (!hostel) throw new NotFoundException('Hostel not found');
    return hostel;
  }

  // ── Soft-delete / restore / purge ────────────────

  async softDelete(hostelId: string, userId: string, role: string): Promise<void> {
    const isAdmin = role === 'PLATFORM_ADMIN' || role === 'PLATFORM_SUPPORT';
    const query = isAdmin
      ? `UPDATE hostels SET deleted_at = NOW() WHERE id = \$1 AND deleted_at IS NULL`
      : `UPDATE hostels SET deleted_at = NOW() WHERE id = \$1 AND owner_id = \$2 AND deleted_at IS NULL`;
    const params = isAdmin ? [hostelId] : [hostelId, userId];
    const result = await this.dataSource.query(query, params);
    if (result[1] === 0) throw new NotFoundException('Hostel not found or already deleted');
  }

  async restore(hostelId: string, userId: string, role: string): Promise<void> {
    const isAdmin = role === 'PLATFORM_ADMIN' || role === 'PLATFORM_SUPPORT';
    const query = isAdmin
      ? `UPDATE hostels SET deleted_at = NULL WHERE id = \$1 AND deleted_at IS NOT NULL`
      : `UPDATE hostels SET deleted_at = NULL WHERE id = \$1 AND owner_id = \$2 AND deleted_at IS NOT NULL`;
    const params = isAdmin ? [hostelId] : [hostelId, userId];
    const result = await this.dataSource.query(query, params);
    if (result[1] === 0) throw new NotFoundException('Hostel not found or not deleted');
  }

  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async purgeDeletedHostels(): Promise<void> {
    const result = await this.dataSource.query(
      `DELETE FROM hostels WHERE deleted_at IS NOT NULL AND deleted_at < NOW() - INTERVAL '60 days'`
    );
    const count = result[1] || 0;
    if (count > 0) console.log(`[Cron] Purged \${count} hostels deleted 60+ days ago`);
  }

  // ── Featured ──────────────────────────────────────

  async findFeatured(university?: string): Promise<any[]> {
    const where: any = { status: HostelStatus.ACTIVE, verified: true, deletedAt: IsNull() };
    if (university) where.university = university;
    const hostels = await this.hostelRepo.find({
      where,
      relations: ['amenities'],
      order: { createdAt: 'DESC' },
      take: 20,
    });

    const result = [];
    for (const h of hostels) {
      const minPrice = await this.hostelRepo.query(
        `SELECT MIN(r.price_pesewas)::bigint AS min_price
         FROM rooms r
         JOIN floors f ON f.id = r.floor_id
         JOIN buildings b ON b.id = f.building_id
         WHERE b.hostel_id = $1`,
        [h.id],
      );
      result.push({
        ...h,
        fromPricePesewas: parseInt(minPrice[0]?.min_price ?? '0', 10),
      });
    }
    return result;
  }

  // ── Rooms ─────────────────────────────────────────

  async findRoomsByHostel(hostelId: string): Promise<Room[]> {
    await this.findById(hostelId);

    return this.roomRepo.find({
      where: { floor: { building: { hostelId } } },
      relations: ['beds', 'floor', 'floor.building'],
      order: { number: 'ASC' },
    });
  }

  async findRoomById(id: string): Promise<Room> {
    const room = await this.roomRepo.findOne({
      where: { id },
      relations: ['beds', 'floor', 'floor.building', 'floor.building.hostel'],
    });
    if (!room) throw new NotFoundException('Room not found');
    return room;
  }

  // ── Beds ──────────────────────────────────────────

  async findBedsByRoom(roomId: string): Promise<Bed[]> {
    return this.bedRepo.find({
      where: { roomId },
      order: { label: 'ASC' },
    });
  }

  // ── Amenities ─────────────────────────────────────

  async findAllAmenities(): Promise<Amenity[]> {
    return this.amenityRepo.find({ order: { sortOrder: 'ASC' } });
  }

  // ── Owner actions ─────────────────────────────────

  async verifyOwnership(hostelId: string, ownerId: string): Promise<Hostel> {
    const hostel = await this.findById(hostelId);
    if (hostel.ownerId !== ownerId) {
      throw new ForbiddenException('Not your hostel');
    }
    return hostel;
  }
}
