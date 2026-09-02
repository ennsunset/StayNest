// src/database/migrations/1723747200000-Stage1UsersAndHostels.ts

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Stage1UsersAndHostels1723747200000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // ── Users ───────────────────────────────────────
    await queryRunner.query(`
      CREATE TYPE user_role AS ENUM (
        'STUDENT', 'OWNER', 'PLATFORM_SUPPORT',
        'PLATFORM_FINANCE', 'PLATFORM_ADMIN', 'SUPER_ADMIN'
      )
    `);

    await queryRunner.query(`
      CREATE TABLE users (
        id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        full_name       VARCHAR(100) NOT NULL,
        email           VARCHAR(255) NOT NULL,
        phone           VARCHAR(20),
        password_hash   VARCHAR(255) NOT NULL,
        role            user_role NOT NULL DEFAULT 'STUDENT',
        university      VARCHAR(100),
        level           VARCHAR(20),
        avatar_url      VARCHAR(500),
        email_verified  BOOLEAN NOT NULL DEFAULT FALSE,
        phone_verified  BOOLEAN NOT NULL DEFAULT FALSE,
        id_verified     BOOLEAN NOT NULL DEFAULT FALSE,
        is_active       BOOLEAN NOT NULL DEFAULT TRUE,
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    await queryRunner.query(`CREATE UNIQUE INDEX idx_users_email ON users (email)`);

    // ── Amenities ───────────────────────────────────
    await queryRunner.query(`
      CREATE TABLE amenities (
        id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name        VARCHAR(50) NOT NULL,
        icon        VARCHAR(50),
        sort_order  INT NOT NULL DEFAULT 0
      )
    `);

    await queryRunner.query(`CREATE UNIQUE INDEX idx_amenities_name ON amenities (name)`);

    // Seed default amenities
    await queryRunner.query(`
      INSERT INTO amenities (name, icon, sort_order) VALUES
        ('WiFi', 'wifi', 1),
        ('Backup Power', 'power', 2),
        ('Security', 'security', 3),
        ('Laundry', 'laundry', 4),
        ('Air Conditioning', 'ac', 5),
        ('Water Supply', 'water', 6),
        ('Study Room', 'study', 7),
        ('Kitchen', 'kitchen', 8)
    `);

    // ── Hostels ─────────────────────────────────────
    await queryRunner.query(`
      CREATE TYPE hostel_status AS ENUM (
        'DRAFT', 'PENDING_REVIEW', 'ACTIVE', 'REJECTED', 'SUSPENDED'
      )
    `);

    await queryRunner.query(`
      CREATE TABLE hostels (
        id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        owner_id        UUID NOT NULL REFERENCES users(id),
        name            VARCHAR(200) NOT NULL,
        description     TEXT,
        address         VARCHAR(500) NOT NULL,
        city            VARCHAR(100) NOT NULL,
        location        GEOGRAPHY(Point, 4326),
        status          hostel_status NOT NULL DEFAULT 'DRAFT',
        verified        BOOLEAN NOT NULL DEFAULT FALSE,
        gender_policy   VARCHAR(50),
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    await queryRunner.query(`CREATE INDEX idx_hostels_owner ON hostels (owner_id)`);
    await queryRunner.query(`CREATE INDEX idx_hostels_status ON hostels (status)`);
    await queryRunner.query(`CREATE INDEX idx_hostels_location ON hostels USING GIST (location)`);

    // Hostel-amenity join table
    await queryRunner.query(`
      CREATE TABLE hostel_amenities (
        hostel_id   UUID NOT NULL REFERENCES hostels(id) ON DELETE CASCADE,
        amenity_id  UUID NOT NULL REFERENCES amenities(id) ON DELETE CASCADE,
        PRIMARY KEY (hostel_id, amenity_id)
      )
    `);

    // ── Buildings ───────────────────────────────────
    await queryRunner.query(`
      CREATE TABLE buildings (
        id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        hostel_id   UUID NOT NULL REFERENCES hostels(id) ON DELETE CASCADE,
        name        VARCHAR(100) NOT NULL,
        created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    // ── Floors ──────────────────────────────────────
    await queryRunner.query(`
      CREATE TABLE floors (
        id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        building_id  UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
        label        VARCHAR(50) NOT NULL,
        sort_order   INT NOT NULL DEFAULT 0,
        created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    // ── Rooms ───────────────────────────────────────
    await queryRunner.query(`
      CREATE TYPE room_type AS ENUM ('1-in-a-room', '2-in-a-room', '3-in-a-room', '4-in-a-room')
    `);

    await queryRunner.query(`
      CREATE TABLE rooms (
        id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        floor_id        UUID NOT NULL REFERENCES floors(id) ON DELETE CASCADE,
        number          VARCHAR(20) NOT NULL,
        type            room_type NOT NULL,
        price_pesewas   BIGINT NOT NULL,
        description     TEXT,
        has_ac          BOOLEAN NOT NULL DEFAULT FALSE,
        has_private_bath BOOLEAN NOT NULL DEFAULT FALSE,
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    // ── Beds — the atomic bookable unit ─────────────
    await queryRunner.query(`
      CREATE TYPE bed_status AS ENUM (
        'AVAILABLE', 'HELD', 'BOOKED', 'OCCUPIED', 'MAINTENANCE', 'DISABLED'
      )
    `);

    await queryRunner.query(`
      CREATE TABLE beds (
        id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        room_id     UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
        label       VARCHAR(20) NOT NULL,
        status      bed_status NOT NULL DEFAULT 'AVAILABLE',
        held_until  TIMESTAMPTZ,
        created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    await queryRunner.query(`CREATE INDEX idx_beds_room ON beds (room_id)`);
    await queryRunner.query(`CREATE INDEX idx_beds_status ON beds (status)`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS beds`);
    await queryRunner.query(`DROP TYPE IF EXISTS bed_status`);
    await queryRunner.query(`DROP TABLE IF EXISTS rooms`);
    await queryRunner.query(`DROP TYPE IF EXISTS room_type`);
    await queryRunner.query(`DROP TABLE IF EXISTS floors`);
    await queryRunner.query(`DROP TABLE IF EXISTS buildings`);
    await queryRunner.query(`DROP TABLE IF EXISTS hostel_amenities`);
    await queryRunner.query(`DROP TABLE IF EXISTS hostels`);
    await queryRunner.query(`DROP TYPE IF EXISTS hostel_status`);
    await queryRunner.query(`DROP TABLE IF EXISTS amenities`);
    await queryRunner.query(`DROP TABLE IF EXISTS users`);
    await queryRunner.query(`DROP TYPE IF EXISTS user_role`);
  }
}
