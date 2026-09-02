import { MigrationInterface, QueryRunner } from 'typeorm';

export class ExpandRoomTypes1724700000000 implements MigrationInterface {
  public async up(runner: QueryRunner): Promise<void> {
    // Expand room_type enum to 8
    await runner.query(`ALTER TYPE room_type ADD VALUE IF NOT EXISTS '5-in-a-room'`);
    await runner.query(`ALTER TYPE room_type ADD VALUE IF NOT EXISTS '6-in-a-room'`);
    await runner.query(`ALTER TYPE room_type ADD VALUE IF NOT EXISTS '7-in-a-room'`);
    await runner.query(`ALTER TYPE room_type ADD VALUE IF NOT EXISTS '8-in-a-room'`);

    // Add room features
    await runner.query(`ALTER TABLE rooms ADD COLUMN IF NOT EXISTS has_fan BOOLEAN NOT NULL DEFAULT false`);
    await runner.query(`ALTER TABLE rooms ADD COLUMN IF NOT EXISTS socket_count INT NOT NULL DEFAULT 1`);
  }

  public async down(runner: QueryRunner): Promise<void> {
    await runner.query(`ALTER TABLE rooms DROP COLUMN IF EXISTS has_fan`);
    await runner.query(`ALTER TABLE rooms DROP COLUMN IF EXISTS socket_count`);
  }
}
