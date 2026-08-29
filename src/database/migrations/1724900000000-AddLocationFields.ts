import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddLocationFields1724900000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS region VARCHAR(100);
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS area VARCHAR(200);
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS landmark VARCHAR(300);
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS digital_address VARCHAR(50);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE hostels DROP COLUMN IF EXISTS region;
      ALTER TABLE hostels DROP COLUMN IF EXISTS area;
      ALTER TABLE hostels DROP COLUMN IF EXISTS landmark;
      ALTER TABLE hostels DROP COLUMN IF EXISTS digital_address;
    `);
  }
}
