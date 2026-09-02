"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OwnerService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("typeorm");
let OwnerService = class OwnerService {
    constructor(ds) {
        this.ds = ds;
    }
    _safeInt(val) {
        if (typeof val === 'number')
            return val;
        if (typeof val === 'string')
            return parseInt(val, 10) || 0;
        return 0;
    }
    async getHostels(ownerId) {
        const hostels = await this.ds.query(`
      SELECT h.id, h.name, h.description, h.address, h.city, h.status, h.verified,
             h.gender_policy AS "genderPolicy", h.image_urls AS "imageUrls",
             h.created_at AS "createdAt", h.updated_at AS "updatedAt"
      FROM hostels h
      WHERE h.owner_id = $1
      ORDER BY h.created_at DESC
    `, [ownerId]);
        for (const h of hostels) {
            const buildings = await this.ds.query(`
        SELECT b.id, b.name, b.hostel_id AS "hostelId"
        FROM buildings b WHERE b.hostel_id = $1
      `, [h.id]);
            for (const b of buildings) {
                const floors = await this.ds.query(`
          SELECT f.id, f.label, f.sort_order AS "sortOrder"
          FROM floors f WHERE f.building_id = $1 ORDER BY f.sort_order
        `, [b.id]);
                for (const fl of floors) {
                    const rooms = await this.ds.query(`
            SELECT r.id, r.number, r.type, r.price_pesewas AS "pricePesewas",
                   r.description, r.has_ac AS "hasAC", r.has_private_bath AS "hasPrivateBath"
            FROM rooms r WHERE r.floor_id = $1
          `, [fl.id]);
                    for (const rm of rooms) {
                        rm.beds = await this.ds.query(`
              SELECT bd.id, bd.label, bd.status
              FROM beds bd WHERE bd.room_id = $1
            `, [rm.id]);
                    }
                    fl.rooms = rooms;
                }
                b.floors = floors;
            }
            h.buildings = buildings;
        }
        return { data: hostels };
    }
    async _verifyOwnership(ownerId, bookingId) {
        const rows = await this.ds.query(`
      SELECT b.id, b.status, b.reference,
             h.owner_id
      FROM bookings b
      JOIN beds bd ON bd.id = b.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE b.id = $1
    `, [bookingId]);
        if (rows.length === 0) {
            throw new common_1.NotFoundException('Booking not found');
        }
        if (rows[0].owner_id !== ownerId) {
            throw new common_1.ForbiddenException('This booking does not belong to your hostel');
        }
        return rows[0];
    }
    async getDashboard(ownerId) {
        const bedStats = await this.ds.query(`
      SELECT
        COUNT(bd.id)::int AS total_beds,
        COUNT(bd.id) FILTER (WHERE bd.status IN ('OCCUPIED', 'BOOKED'))::int AS occupied_beds,
        COUNT(bd.id) FILTER (WHERE bd.status = 'AVAILABLE')::int AS available_beds,
        COUNT(bd.id) FILTER (WHERE bd.status = 'MAINTENANCE')::int AS maintenance_beds
      FROM beds bd
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE h.owner_id = $1 AND h.status = 'ACTIVE'
    `, [ownerId]);
        const stats = bedStats[0] || { total_beds: 0, occupied_beds: 0, available_beds: 0, maintenance_beds: 0 };
        const totalBeds = this._safeInt(stats.total_beds);
        const occupiedBeds = this._safeInt(stats.occupied_beds);
        const occupancyRate = totalBeds > 0 ? Math.round((occupiedBeds / totalBeds) * 1000) / 10 : 0;
        const revenueRows = await this.ds.query(`
      SELECT
        COALESCE(SUM(p.amount_pesewas), 0) AS total_revenue_pesewas,
        COALESCE(SUM(bk.platform_fee_pesewas), 0) AS total_commission_pesewas,
        COALESCE(SUM(p.amount_pesewas) FILTER (
          WHERE p.created_at >= date_trunc('month', NOW())
        ), 0) AS this_month_pesewas
      FROM payments p
      JOIN bookings bk ON bk.id = p.booking_id
      JOIN beds bd ON bd.id = bk.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE h.owner_id = $1 AND p.status = 'SUCCESS'
    `, [ownerId]);
        const rev = revenueRows[0] || {};
        const pendingRows = await this.ds.query(`
      SELECT COUNT(*)::int AS count
      FROM bookings bk
      JOIN beds bd ON bd.id = bk.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE h.owner_id = $1 AND bk.status = 'CONFIRMED'
    `, [ownerId]);
        const hostelRows = await this.ds.query(`
      SELECT COUNT(*)::int AS count FROM hostels WHERE owner_id = $1 AND status = 'ACTIVE'
    `, [ownerId]);
        return {
            occupancy: {
                rate: occupancyRate,
                totalBeds,
                occupiedBeds,
                availableBeds: this._safeInt(stats.available_beds),
                maintenanceBeds: this._safeInt(stats.maintenance_beds),
            },
            revenue: {
                totalPesewas: this._safeInt(rev.total_revenue_pesewas),
                commissionPesewas: this._safeInt(rev.total_commission_pesewas),
                netPesewas: this._safeInt(rev.total_revenue_pesewas) - this._safeInt(rev.total_commission_pesewas),
                thisMonthPesewas: this._safeInt(rev.this_month_pesewas),
            },
            pendingRequests: this._safeInt(pendingRows[0]?.count),
            maintenanceRequests: this._safeInt(stats.maintenance_beds),
            activeHostels: this._safeInt(hostelRows[0]?.count),
        };
    }
    async getBookings(ownerId, opts) {
        const offset = (opts.page - 1) * opts.limit;
        const statusFilter = opts.status ? "AND bk.status = $4" : "";
        const params = [ownerId, opts.limit, offset];
        if (opts.status)
            params.push(opts.status);
        const rows = await this.ds.query(`
      SELECT
        bk.id, bk.reference, bk.status, bk.price_pesewas, bk.platform_fee_pesewas,
        bk.total_pesewas, bk.period_label, bk.check_in_date, bk.cancel_reason,
        bk.created_at, bk.held_until,
        u.id AS student_id, u.full_name AS student_name, u.email AS student_email,
        u.level AS student_level, u.university AS student_university,
        bd.label AS bed_label,
        r.number AS room_number, r.type AS room_type,
        h.name AS hostel_name, h.id AS hostel_id
      FROM bookings bk
      JOIN users u ON u.id = bk.student_id
      JOIN beds bd ON bd.id = bk.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE h.owner_id = $1 ${statusFilter}
      ORDER BY bk.created_at DESC
      LIMIT $2 OFFSET $3
    `, params);
        const countRows = await this.ds.query(`
      SELECT COUNT(*)::int AS total
      FROM bookings bk
      JOIN beds bd ON bd.id = bk.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE h.owner_id = $1 ${opts.status ? "AND bk.status = $2" : ""}
    `, opts.status ? [ownerId, opts.status] : [ownerId]);
        return {
            data: rows.map((r) => ({
                id: r.id,
                reference: r.reference,
                status: r.status,
                pricePesewas: this._safeInt(r.price_pesewas),
                platformFeePesewas: this._safeInt(r.platform_fee_pesewas),
                totalPesewas: this._safeInt(r.total_pesewas),
                periodLabel: r.period_label,
                checkInDate: r.check_in_date,
                cancelReason: r.cancel_reason,
                createdAt: r.created_at,
                heldUntil: r.held_until,
                student: {
                    id: r.student_id,
                    name: r.student_name,
                    email: r.student_email,
                    level: r.student_level,
                    university: r.student_university,
                },
                bed: r.bed_label,
                room: r.room_number,
                roomType: r.room_type,
                hostelName: r.hostel_name,
                hostelId: r.hostel_id,
            })),
            total: this._safeInt(countRows[0]?.total),
            page: opts.page,
            limit: opts.limit,
        };
    }
    async acceptBooking(ownerId, bookingId) {
        const booking = await this._verifyOwnership(ownerId, bookingId);
        if (booking.status !== 'CONFIRMED') {
            throw new common_1.BadRequestException('Only CONFIRMED bookings can be accepted. Current status: ' + booking.status);
        }
        await this.ds.query(`
      UPDATE bookings SET status = 'CHECKED_IN', updated_at = NOW() WHERE id = $1
    `, [bookingId]);
        await this.ds.query(`
      UPDATE beds SET status = 'OCCUPIED', updated_at = NOW()
      WHERE id = (SELECT bed_id FROM bookings WHERE id = $1)
    `, [bookingId]);
        return { message: 'Booking accepted', bookingId, status: 'CHECKED_IN' };
    }
    async declineBooking(ownerId, bookingId, reason) {
        if (!reason || reason.trim().length === 0) {
            throw new common_1.BadRequestException('Decline reason is required');
        }
        const booking = await this._verifyOwnership(ownerId, bookingId);
        if (!['HELD', 'PENDING_PAYMENT', 'CONFIRMED'].includes(booking.status)) {
            throw new common_1.BadRequestException('Cannot decline a booking with status: ' + booking.status);
        }
        await this.ds.query(`
      UPDATE bookings
      SET status = 'CANCELLED', cancel_reason = $2, updated_at = NOW()
      WHERE id = $1
    `, [bookingId, reason.trim()]);
        await this.ds.query(`
      UPDATE beds SET status = 'AVAILABLE', updated_at = NOW()
      WHERE id = (SELECT bed_id FROM bookings WHERE id = $1)
    `, [bookingId]);
        return { message: 'Booking declined', bookingId, status: 'CANCELLED' };
    }
    async getTenants(ownerId) {
        const rows = await this.ds.query(`
      SELECT
        u.id, u.full_name, u.email, u.phone, u.university, u.level,
        u.avatar_url,
        bk.id AS booking_id, bk.reference, bk.status AS booking_status,
        bk.total_pesewas, bk.period_label, bk.check_in_date,
        bd.label AS bed_label,
        r.number AS room_number,
        h.name AS hostel_name, h.id AS hostel_id,
        CASE
          WHEN p.id IS NOT NULL AND p.status = 'SUCCESS' THEN 'PAID'
          ELSE 'PENDING'
        END AS payment_status
      FROM bookings bk
      JOIN users u ON u.id = bk.student_id
      JOIN beds bd ON bd.id = bk.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      LEFT JOIN payments p ON p.booking_id = bk.id AND p.status = 'SUCCESS'
      WHERE h.owner_id = $1
        AND bk.status IN ('CONFIRMED', 'CHECKED_IN')
      ORDER BY bk.created_at DESC
    `, [ownerId]);
        return rows.map((r) => ({
            id: r.id,
            fullName: r.full_name,
            email: r.email,
            phone: r.phone,
            university: r.university,
            level: r.level,
            avatarUrl: r.avatar_url,
            booking: {
                id: r.booking_id,
                reference: r.reference,
                status: r.booking_status,
                totalPesewas: this._safeInt(r.total_pesewas),
                periodLabel: r.period_label,
                checkInDate: r.check_in_date,
            },
            bed: r.bed_label,
            room: r.room_number,
            hostelName: r.hostel_name,
            hostelId: r.hostel_id,
            paymentStatus: r.payment_status,
        }));
    }
    async getPayments(ownerId, opts) {
        const offset = (opts.page - 1) * opts.limit;
        const rows = await this.ds.query(`
      SELECT
        p.id, p.provider_reference, p.status, p.amount_pesewas,
        p.channel, p.created_at,
        bk.reference AS booking_reference, bk.price_pesewas,
        bk.platform_fee_pesewas, bk.total_pesewas,
        u.full_name AS student_name,
        h.name AS hostel_name,
        r.number AS room_number
      FROM payments p
      JOIN bookings bk ON bk.id = p.booking_id
      JOIN users u ON u.id = bk.student_id
      JOIN beds bd ON bd.id = bk.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE h.owner_id = $1
      ORDER BY p.created_at DESC
      LIMIT $2 OFFSET $3
    `, [ownerId, opts.limit, offset]);
        const countRows = await this.ds.query(`
      SELECT COUNT(*)::int AS total
      FROM payments p
      JOIN bookings bk ON bk.id = p.booking_id
      JOIN beds bd ON bd.id = bk.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE h.owner_id = $1
    `, [ownerId]);
        const summaryRows = await this.ds.query(`
      SELECT
        COALESCE(SUM(p.amount_pesewas) FILTER (WHERE p.status = 'SUCCESS'), 0) AS settled_pesewas,
        COALESCE(SUM(bk.total_pesewas) FILTER (
          WHERE p.status = 'PENDING' OR (bk.status = 'CONFIRMED' AND p.id IS NULL)
        ), 0) AS pending_pesewas,
        COALESCE(SUM(p.amount_pesewas) FILTER (
          WHERE p.status = 'SUCCESS' AND p.created_at >= date_trunc('month', NOW())
        ), 0) AS this_month_pesewas,
        COALESCE(SUM(bk.platform_fee_pesewas) FILTER (WHERE p.status = 'SUCCESS'), 0) AS total_commission_pesewas
      FROM payments p
      JOIN bookings bk ON bk.id = p.booking_id
      JOIN beds bd ON bd.id = bk.bed_id
      JOIN rooms r ON r.id = bd.room_id
      JOIN floors f ON f.id = r.floor_id
      JOIN buildings bl ON bl.id = f.building_id
      JOIN hostels h ON h.id = bl.hostel_id
      WHERE h.owner_id = $1
    `, [ownerId]);
        const summary = summaryRows[0] || {};
        return {
            summary: {
                settledPesewas: this._safeInt(summary.settled_pesewas),
                pendingPesewas: this._safeInt(summary.pending_pesewas),
                thisMonthPesewas: this._safeInt(summary.this_month_pesewas),
                commissionPesewas: this._safeInt(summary.total_commission_pesewas),
            },
            data: rows.map((r) => ({
                id: r.id,
                providerReference: r.provider_reference,
                status: r.status,
                amountPesewas: this._safeInt(r.amount_pesewas),
                channel: r.channel,
                createdAt: r.created_at,
                bookingReference: r.booking_reference,
                pricePesewas: this._safeInt(r.price_pesewas),
                platformFeePesewas: this._safeInt(r.platform_fee_pesewas),
                totalPesewas: this._safeInt(r.total_pesewas),
                studentName: r.student_name,
                hostelName: r.hostel_name,
                room: r.room_number,
            })),
            total: this._safeInt(countRows[0]?.total),
            page: opts.page,
            limit: opts.limit,
        };
    }
    bedCountFromType(type) {
        const map = {
            '1-in-a-room': 1,
            '2-in-a-room': 2,
            '3-in-a-room': 3,
            '4-in-a-room': 4,
        };
        return map[type] || 2;
    }
    async createRoom(ownerId, hostelId, dto) {
        const [hostel] = await this.ds.query('SELECT id FROM hostels WHERE id = $1 AND owner_id = $2', [hostelId, ownerId]);
        if (!hostel)
            throw new common_1.NotFoundException('Hostel not found');
        const [floor] = await this.ds.query('SELECT f.id FROM floors f JOIN buildings b ON b.id = f.building_id WHERE f.id = $1 AND b.hostel_id = $2', [dto.floorId, hostelId]);
        if (!floor)
            throw new common_1.NotFoundException('Floor not found in this hostel');
        const [room] = await this.ds.query('INSERT INTO rooms (floor_id, number, type, price_pesewas, price_per_semester_pesewas, has_ac, has_private_bath, has_fan, socket_count, has_tv, description) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id, number, type, price_pesewas AS "pricePesewas", has_ac AS "hasAC", has_private_bath AS "hasPrivateBath", has_fan AS "hasFan", socket_count AS "socketCount", has_tv AS "hasTV"', [dto.floorId, dto.number, dto.type, dto.pricePesewas, dto.pricePerSemesterPesewas || null, dto.hasAC || false, dto.hasPrivateBath || false, dto.hasFan || false, dto.socketCount || 1, dto.hasTV || false, dto.description || null]);
        const bedCount = dto.bedCount || this.bedCountFromType(dto.type);
        const beds = [];
        for (let i = 0; i < bedCount; i++) {
            const label = 'Bed ' + String.fromCharCode(65 + i);
            const [bed] = await this.ds.query('INSERT INTO beds (room_id, label) VALUES ($1, $2) RETURNING id, label, status', [room.id, label]);
            beds.push(bed);
        }
        room.beds = beds;
        return room;
    }
    async addBeds(ownerId, roomId, count) {
        if (count < 1 || count > 10)
            throw new common_1.BadRequestException('Count must be 1-10');
        const [roomInfo] = await this.ds.query('SELECT r.type, (SELECT COUNT(*)::int FROM beds WHERE room_id = r.id) AS current_beds FROM rooms r WHERE r.id = $1', [roomId]);
        if (roomInfo) {
            const maxBeds = parseInt(roomInfo.type.split('-')[0], 10) || 99;
            const currentBeds = roomInfo.current_beds || 0;
            if (currentBeds + count > maxBeds) {
                throw new common_1.BadRequestException('Room is ' + roomInfo.type + ' (max ' + maxBeds + ' beds). Currently has ' + currentBeds + '. Cannot add ' + count + ' more.');
            }
        }
        const [room] = await this.ds.query('SELECT r.id FROM rooms r JOIN floors f ON f.id = r.floor_id JOIN buildings b ON b.id = f.building_id JOIN hostels h ON h.id = b.hostel_id WHERE r.id = $1 AND h.owner_id = $2', [roomId, ownerId]);
        if (!room)
            throw new common_1.NotFoundException('Room not found');
        const [{ max_label }] = await this.ds.query("SELECT COALESCE(MAX(ASCII(SUBSTRING(label FROM 5 FOR 1))), 64) AS max_label FROM beds WHERE room_id = $1", [roomId]);
        const beds = [];
        for (let i = 0; i < count; i++) {
            const label = 'Bed ' + String.fromCharCode(Number(max_label) + 1 + i);
            const [bed] = await this.ds.query('INSERT INTO beds (room_id, label) VALUES ($1, $2) RETURNING id, label, status', [roomId, label]);
            beds.push(bed);
        }
        return { added: beds.length, beds };
    }
    async updateBedStatus(ownerId, bedId, status) {
        const allowed = ['AVAILABLE', 'MAINTENANCE', 'DISABLED'];
        if (!allowed.includes(status)) {
            throw new common_1.BadRequestException('Status must be one of: ' + allowed.join(', '));
        }
        const [bed] = await this.ds.query('SELECT bd.id, bd.status FROM beds bd JOIN rooms r ON r.id = bd.room_id JOIN floors f ON f.id = r.floor_id JOIN buildings b ON b.id = f.building_id JOIN hostels h ON h.id = b.hostel_id WHERE bd.id = $1 AND h.owner_id = $2', [bedId, ownerId]);
        if (!bed)
            throw new common_1.NotFoundException('Bed not found');
        const blocked = ['OCCUPIED', 'BOOKED', 'HELD'];
        if (blocked.includes(bed.status)) {
            throw new common_1.BadRequestException('Cannot change status of ' + bed.status + ' bed');
        }
        await this.ds.query('UPDATE beds SET status = $1, updated_at = NOW() WHERE id = $2', [status, bedId]);
        return { id: bedId, status };
    }
    async getRoomsForHostel(ownerId, hostelId) {
        const [hostel] = await this.ds.query('SELECT id FROM hostels WHERE id = $1 AND owner_id = $2', [hostelId, ownerId]);
        if (!hostel)
            throw new common_1.NotFoundException('Hostel not found');
        const rooms = await this.ds.query('SELECT r.id, r.number, r.type, r.price_pesewas AS "pricePesewas", r.has_ac AS "hasAC", r.has_private_bath AS "hasPrivateBath", r.has_fan AS "hasFan", r.socket_count AS "socketCount", r.has_tv AS "hasTV", f.label AS "floorLabel", COUNT(bd.id)::int AS "totalBeds", COUNT(bd.id) FILTER (WHERE bd.status IN (' + "'OCCUPIED','BOOKED','HELD'" + '))::int AS "occupiedBeds", CASE WHEN COUNT(bd.id) > 0 AND COUNT(bd.id) = COUNT(bd.id) FILTER (WHERE bd.status IN (' + "'OCCUPIED','BOOKED','HELD'" + ')) THEN ' + "'OCCUPIED'" + ' WHEN COUNT(bd.id) FILTER (WHERE bd.status = ' + "'MAINTENANCE'" + ') > 0 THEN ' + "'MAINTENANCE'" + ' ELSE ' + "'AVAILABLE'" + ' END AS "dominantStatus" FROM rooms r JOIN floors f ON f.id = r.floor_id JOIN buildings b ON b.id = f.building_id LEFT JOIN beds bd ON bd.room_id = r.id WHERE b.hostel_id = $1 GROUP BY r.id, r.number, r.type, r.price_pesewas, r.has_ac, r.has_private_bath, f.label ORDER BY f.label, r.number', [hostelId]);
        return { data: rooms };
    }
    async getBedsForRoom(ownerId, roomId) {
        const [room] = await this.ds.query('SELECT r.id, r.number FROM rooms r JOIN floors f ON f.id = r.floor_id JOIN buildings b ON b.id = f.building_id JOIN hostels h ON h.id = b.hostel_id WHERE r.id = $1 AND h.owner_id = $2', [roomId, ownerId]);
        if (!room)
            throw new common_1.NotFoundException('Room not found');
        const beds = await this.ds.query(`SELECT bd.id, bd.label, bd.status, bd.held_until AS "heldUntil", CASE WHEN bd.status = 'OCCUPIED' THEN (SELECT SPLIT_PART(u.full_name, ' ', 1) || ' ' || LEFT(SPLIT_PART(u.full_name, ' ', 2), 1) || '.' FROM bookings bk JOIN users u ON u.id = bk.student_id WHERE bk.bed_id = bd.id AND bk.status IN ('CONFIRMED', 'CHECKED_IN') LIMIT 1) ELSE NULL END AS "tenantName" FROM beds bd WHERE bd.room_id = $1 ORDER BY bd.label`, [roomId]);
        const [roomDetail] = await this.ds.query('SELECT r.type FROM rooms r WHERE r.id = $1', [roomId]);
        const maxBeds = roomDetail ? parseInt(roomDetail.type.split('-')[0], 10) : 99;
        return { roomNumber: room.number, roomType: roomDetail?.type || '', maxBeds, beds };
    }
    async getFloorsForHostel(ownerId, hostelId) {
        const [hostel] = await this.ds.query('SELECT id FROM hostels WHERE id = $1 AND owner_id = $2', [hostelId, ownerId]);
        if (!hostel)
            throw new common_1.NotFoundException('Hostel not found');
        const floors = await this.ds.query('SELECT f.id, f.label, b.name AS "buildingName" FROM floors f JOIN buildings b ON b.id = f.building_id WHERE b.hostel_id = $1 ORDER BY b.name, f.sort_order', [hostelId]);
        return { data: floors };
    }
    async updateRoom(ownerId, roomId, dto) {
        const [room] = await this.ds.query('SELECT r.id, r.type FROM rooms r JOIN floors f ON f.id = r.floor_id JOIN buildings b ON b.id = f.building_id JOIN hostels h ON h.id = b.hostel_id WHERE r.id = $1 AND h.owner_id = $2', [roomId, ownerId]);
        if (!room)
            throw new common_1.NotFoundException('Room not found');
        const sets = [];
        const params = [];
        let pi = 0;
        const p = () => { pi++; return '$' + pi; };
        if (dto.type !== undefined) {
            sets.push('type = ' + p());
            params.push(dto.type);
        }
        if (dto.pricePesewas !== undefined) {
            sets.push('price_pesewas = ' + p());
            params.push(dto.pricePesewas);
        }
        if (dto.pricePerSemesterPesewas !== undefined) {
            sets.push('price_per_semester_pesewas = ' + p());
            params.push(dto.pricePerSemesterPesewas);
        }
        if (dto.hasAC !== undefined) {
            sets.push('has_ac = ' + p());
            params.push(dto.hasAC);
        }
        if (dto.hasFan !== undefined) {
            sets.push('has_fan = ' + p());
            params.push(dto.hasFan);
        }
        if (dto.hasPrivateBath !== undefined) {
            sets.push('has_private_bath = ' + p());
            params.push(dto.hasPrivateBath);
        }
        if (dto.hasTV !== undefined) {
            sets.push('has_tv = ' + p());
            params.push(dto.hasTV);
        }
        if (dto.socketCount !== undefined) {
            sets.push('socket_count = ' + p());
            params.push(dto.socketCount);
        }
        if (sets.length === 0)
            throw new common_1.BadRequestException('Nothing to update');
        params.push(roomId);
        await this.ds.query('UPDATE rooms SET ' + sets.join(', ') + ' WHERE id = ' + p(), params);
        if (dto.type) {
            const newMax = parseInt(dto.type.split('-')[0], 10) || 99;
            const [bedInfo] = await this.ds.query("SELECT COUNT(*)::int AS total, COUNT(*) FILTER (WHERE status IN ('OCCUPIED','BOOKED','HELD'))::int AS locked FROM beds WHERE room_id = $1", [roomId]);
            const total = bedInfo?.total || 0;
            const locked = bedInfo?.locked || 0;
            if (newMax < total) {
                if (locked > newMax) {
                    throw new common_1.BadRequestException('Cannot reduce to ' + newMax + '-in-a-room: ' + locked + ' beds are currently booked/occupied. Check out students first.');
                }
                const toRemove = total - newMax;
                await this.ds.query("DELETE FROM beds WHERE id IN (SELECT id FROM beds WHERE room_id = $1 AND status = 'AVAILABLE' ORDER BY label DESC LIMIT $2)", [roomId, toRemove]);
            }
            else if (newMax > total) {
                const toAdd = newMax - total;
                const [maxLabel] = await this.ds.query("SELECT COALESCE(MAX(ASCII(SUBSTRING(label FROM 5 FOR 1))), 64) AS max_label FROM beds WHERE room_id = $1", [roomId]);
                const startChar = Number(maxLabel?.max_label || 64);
                for (let i = 0; i < toAdd; i++) {
                    const label = 'Bed ' + String.fromCharCode(startChar + 1 + i);
                    await this.ds.query('INSERT INTO beds (room_id, label) VALUES ($1, $2)', [roomId, label]);
                }
            }
        }
        return { updated: true };
    }
    async checkoutBed(ownerId, bedId) {
        const [bed] = await this.ds.query('SELECT bd.id, bd.status, bd.room_id FROM beds bd JOIN rooms r ON r.id = bd.room_id JOIN floors f ON f.id = r.floor_id JOIN buildings b ON b.id = f.building_id JOIN hostels h ON h.id = b.hostel_id WHERE bd.id = $1 AND h.owner_id = $2', [bedId, ownerId]);
        if (!bed)
            throw new common_1.NotFoundException('Bed not found');
        const allowed = ['OCCUPIED', 'BOOKED'];
        if (!allowed.includes(bed.status)) {
            throw new common_1.BadRequestException('Bed is not occupied or booked');
        }
        await this.ds.query("UPDATE bookings SET status = 'COMPLETED' WHERE bed_id = $1 AND status IN ('CONFIRMED', 'CHECKED_IN')", [bedId]);
        await this.ds.query("UPDATE beds SET status = 'AVAILABLE', updated_at = NOW() WHERE id = $1", [bedId]);
        return { id: bedId, status: 'AVAILABLE' };
    }
    async deleteBed(ownerId, bedId) {
        const [bed] = await this.ds.query('SELECT bd.id, bd.status FROM beds bd JOIN rooms r ON r.id = bd.room_id JOIN floors f ON f.id = r.floor_id JOIN buildings b ON b.id = f.building_id JOIN hostels h ON h.id = b.hostel_id WHERE bd.id = $1 AND h.owner_id = $2', [bedId, ownerId]);
        if (!bed)
            throw new common_1.NotFoundException('Bed not found');
        const blocked = ['OCCUPIED', 'BOOKED', 'HELD'];
        if (blocked.includes(bed.status)) {
            throw new common_1.BadRequestException('Cannot delete ' + bed.status + ' bed');
        }
        await this.ds.query('DELETE FROM beds WHERE id = $1', [bedId]);
        return { deleted: true };
    }
    async createHostel(ownerId, body) {
        const { name, address, city, region, area, landmark, digitalAddress, description, genderPolicy, university, bookingMode, amenityIds, imageUrls, floorCount, gateOpeningTime, gateClosingTime, checkOutTime, cancellationPolicy, houseRules, latitude, longitude } = body;
        if (!name?.trim() || !address?.trim() || !city?.trim()) {
            throw new common_1.BadRequestException('Name, address, and city are required');
        }
        const [hostel] = await this.ds.query(`INSERT INTO hostels (owner_id, name, description, address, city, region, area, landmark, digital_address, gender_policy, university, booking_mode, status, image_urls, gate_opening_time, gate_closing_time, check_out_time, cancellation_policy, house_rules, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 'DRAFT', $13, $14, $15, $16, $17, $18, $19, $20)
       RETURNING id, name, status`, [ownerId, name.trim(), description?.trim() || null, address.trim(), city.trim(),
            region?.trim() || null, area?.trim() || null, landmark?.trim() || null, digitalAddress?.trim() || null,
            genderPolicy || 'MIXED', university || null, bookingMode || 'FLEXIBLE',
            imageUrls || [], gateOpeningTime || null, gateClosingTime || null, checkOutTime || null, cancellationPolicy || 'FLEXIBLE', Array.isArray(houseRules) ? JSON.stringify(houseRules) : (houseRules?.trim() || null), latitude || null, longitude || null]);
        if (amenityIds?.length) {
            const values = amenityIds.map((aid, i) => `($1, $${i + 2})`).join(', ');
            await this.ds.query(`INSERT INTO hostel_amenities (hostel_id, amenity_id) VALUES ${values} ON CONFLICT DO NOTHING`, [hostel.id, ...amenityIds]);
        }
        const [building] = await this.ds.query(`INSERT INTO buildings (hostel_id, name) VALUES ($1, 'Main Block') RETURNING id`, [hostel.id]);
        const floors = Math.min(Math.max(floorCount || 1, 1), 10);
        for (let i = 1; i <= floors; i++) {
            await this.ds.query(`INSERT INTO floors (building_id, label, sort_order) VALUES ($1, $2, $3)`, [building.id, `Floor ${i}`, i]);
        }
        await this.ds.query(`UPDATE hostels SET search_vector = to_tsvector('english',
        coalesce(name,'') || ' ' || coalesce(address,'') || ' ' || coalesce(city,'') || ' ' ||
        coalesce(region,'') || ' ' || coalesce(area,'') || ' ' || coalesce(landmark,'') || ' ' ||
        coalesce(university,'')) WHERE id = $1`, [hostel.id]);
        return { id: hostel.id, name: hostel.name, status: hostel.status };
    }
    async submitHostel(ownerId, hostelId) {
        const [hostel] = await this.ds.query(`SELECT id, status, owner_id FROM hostels WHERE id = $1 AND deleted_at IS NULL`, [hostelId]);
        if (!hostel)
            throw new common_1.NotFoundException('Hostel not found');
        if (hostel.owner_id !== ownerId)
            throw new common_1.ForbiddenException('Not your hostel');
        if (hostel.status !== 'DRAFT' && hostel.status !== 'REJECTED') {
            throw new common_1.BadRequestException('Only DRAFT or REJECTED hostels can be submitted for review');
        }
        await this.ds.query(`UPDATE hostels SET status = 'PENDING_REVIEW', updated_at = NOW() WHERE id = $1`, [hostelId]);
        return { id: hostelId, status: 'PENDING_REVIEW' };
    }
    async getHostel(ownerId, hostelId) {
        const [hostel] = await this.ds.query(`
      SELECT h.id, h.name, h.description, h.address, h.city, h.status,
             h.region, h.area, h.landmark, h.digital_address AS "digitalAddress",
             h.gender_policy AS "genderPolicy", h.university, h.booking_mode AS "bookingMode",
             h.image_urls AS "imageUrls",
             h.gate_opening_time AS "gateOpeningTime",
             h.gate_closing_time AS "gateClosingTime",
             h.check_out_time AS "checkOutTime",
             h.cancellation_policy AS "cancellationPolicy",
             h.house_rules AS "houseRules",
             h.latitude, h.longitude,
             (SELECT COUNT(f.id)::int FROM floors f JOIN buildings b ON b.id = f.building_id WHERE b.hostel_id = h.id) AS "floorCount"
      FROM hostels h
      WHERE h.id = $1 AND h.owner_id = $2 AND h.deleted_at IS NULL
    `, [hostelId, ownerId]);
        if (!hostel)
            throw new common_1.NotFoundException('Hostel not found');
        const amenityRows = await this.ds.query('SELECT amenity_id FROM hostel_amenities WHERE hostel_id = $1', [hostelId]);
        hostel.amenityIds = amenityRows.map((r) => r.amenity_id);
        if (hostel.houseRules) {
            try {
                hostel.houseRules = JSON.parse(hostel.houseRules);
            }
            catch (_) { }
        }
        return hostel;
    }
    async updateHostel(ownerId, hostelId, body) {
        const [hostel] = await this.ds.query('SELECT id, status, owner_id FROM hostels WHERE id = $1 AND deleted_at IS NULL', [hostelId]);
        if (!hostel)
            throw new common_1.NotFoundException('Hostel not found');
        if (hostel.owner_id !== ownerId)
            throw new common_1.ForbiddenException('Not your hostel');
        const allowed = ['DRAFT', 'REJECTED', 'PENDING_REVIEW'];
        if (!allowed.includes(hostel.status)) {
            throw new common_1.BadRequestException('Cannot edit an ACTIVE hostel. Contact support.');
        }
        const { name, address, city, region, area, landmark, digitalAddress, description, genderPolicy, university, bookingMode, amenityIds, imageUrls } = body;
        const sets = [];
        const params = [];
        let pi = 0;
        const p = () => { pi++; return '$' + pi; };
        if (name !== undefined) {
            sets.push('name = ' + p());
            params.push(name.trim());
        }
        if (address !== undefined) {
            sets.push('address = ' + p());
            params.push(address.trim());
        }
        if (city !== undefined) {
            sets.push('city = ' + p());
            params.push(city.trim());
        }
        if (region !== undefined) {
            sets.push('region = ' + p());
            params.push(region.trim());
        }
        if (area !== undefined) {
            sets.push('area = ' + p());
            params.push(area.trim());
        }
        if (landmark !== undefined) {
            sets.push('landmark = ' + p());
            params.push(landmark?.trim() || null);
        }
        if (digitalAddress !== undefined) {
            sets.push('digital_address = ' + p());
            params.push(digitalAddress?.trim() || null);
        }
        if (description !== undefined) {
            sets.push('description = ' + p());
            params.push(description?.trim() || null);
        }
        if (genderPolicy !== undefined) {
            sets.push('gender_policy = ' + p());
            params.push(genderPolicy);
        }
        if (university !== undefined) {
            sets.push('university = ' + p());
            params.push(university);
        }
        if (bookingMode !== undefined) {
            sets.push('booking_mode = ' + p());
            params.push(bookingMode);
        }
        if (imageUrls !== undefined) {
            sets.push('image_urls = ' + p());
            params.push(imageUrls);
        }
        if (body.gateOpeningTime !== undefined) {
            sets.push('gate_opening_time = ' + p());
            params.push(body.gateOpeningTime || null);
        }
        if (body.gateClosingTime !== undefined) {
            sets.push('gate_closing_time = ' + p());
            params.push(body.gateClosingTime || null);
        }
        if (body.checkOutTime !== undefined) {
            sets.push('check_out_time = ' + p());
            params.push(body.checkOutTime || null);
        }
        if (body.cancellationPolicy !== undefined) {
            sets.push('cancellation_policy = ' + p());
            params.push(body.cancellationPolicy);
        }
        if (body.latitude !== undefined) {
            sets.push('latitude = ' + p());
            params.push(body.latitude);
        }
        if (body.longitude !== undefined) {
            sets.push('longitude = ' + p());
            params.push(body.longitude);
        }
        if (body.houseRules !== undefined) {
            sets.push('house_rules = ' + p());
            params.push(Array.isArray(body.houseRules) ? JSON.stringify(body.houseRules) : (body.houseRules?.trim() || null));
        }
        if (sets.length > 0) {
            sets.push('updated_at = NOW()');
            params.push(hostelId);
            await this.ds.query('UPDATE hostels SET ' + sets.join(', ') + ' WHERE id = ' + p(), params);
        }
        if (amenityIds !== undefined) {
            await this.ds.query('DELETE FROM hostel_amenities WHERE hostel_id = $1', [hostelId]);
            if (amenityIds.length > 0) {
                const values = amenityIds.map((aid, i) => '($1, $' + (i + 2) + ')').join(', ');
                await this.ds.query('INSERT INTO hostel_amenities (hostel_id, amenity_id) VALUES ' + values + ' ON CONFLICT DO NOTHING', [hostelId, ...amenityIds]);
            }
        }
        await this.ds.query(`UPDATE hostels SET search_vector = to_tsvector('english',
        coalesce(name,'') || ' ' || coalesce(address,'') || ' ' || coalesce(city,'') || ' ' ||
        coalesce(region,'') || ' ' || coalesce(area,'') || ' ' || coalesce(landmark,'') || ' ' ||
        coalesce(university,'')) WHERE id = $1`, [hostelId]);
        return { id: hostelId, updated: true };
    }
};
exports.OwnerService = OwnerService;
exports.OwnerService = OwnerService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeorm_1.DataSource])
], OwnerService);
//# sourceMappingURL=owner.service.js.map