import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTvToRooms1724800000000 implements MigrationInterface {
  public async up(runner: QueryRunner): Promise<void> {
    await runner.query(`ALTER TABLE rooms ADD COLUMN IF NOT EXISTS has_tv BOOLEAN NOT NULL DEFAULT false`);
  }
  public async down(runner: QueryRunner): Promise<void> {
    await runner.query(`ALTER TABLE rooms DROP COLUMN IF EXISTS has_tv`);
  }
}
