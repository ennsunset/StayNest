import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddUniversityAndSoftDelete1724500000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. University column for school-first feed
    await queryRunner.query(
      `ALTER TABLE hostels ADD COLUMN IF NOT EXISTS university VARCHAR(100)`
    );

    // 2. Convenience lat/lng columns (geography column stays for spatial queries)
    await queryRunner.query(
      `ALTER TABLE hostels ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION`
    );
    await queryRunner.query(
      `ALTER TABLE hostels ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION`
    );

    // 3. Soft-delete timestamp
    await queryRunner.query(
      `ALTER TABLE hostels ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ`
    );

    // 4. Tag existing hostels as KNUST
    await queryRunner.query(
      `UPDATE hostels SET university = 'KNUST' WHERE university IS NULL`
    );

    // 5. Backfill lat/lng from existing location column
    await queryRunner.query(
      `UPDATE hostels SET latitude = ST_Y(location::geometry), longitude = ST_X(location::geometry) WHERE location IS NOT NULL AND latitude IS NULL`
    );

    // 6. Indexes
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_hostels_university ON hostels (university)`
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_hostels_not_deleted ON hostels (id) WHERE deleted_at IS NULL`
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS idx_hostels_not_deleted`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_hostels_university`);
    await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS deleted_at`);
    await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS longitude`);
    await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS latitude`);
    await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS university`);
  }
}
