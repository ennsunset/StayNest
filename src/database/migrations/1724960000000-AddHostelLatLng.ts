import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddHostelLatLng1724960000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION DEFAULT NULL;
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION DEFAULT NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE hostels DROP COLUMN IF EXISTS latitude;
      ALTER TABLE hostels DROP COLUMN IF EXISTS longitude;
    `);
  }
}
