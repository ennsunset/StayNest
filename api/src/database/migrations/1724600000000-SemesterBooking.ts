import { MigrationInterface, QueryRunner } from 'typeorm';

export class SemesterBooking1724600000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Hostel booking mode
    await queryRunner.query(
      `ALTER TABLE hostels ADD COLUMN IF NOT EXISTS booking_mode VARCHAR(20) NOT NULL DEFAULT 'FLEXIBLE'`
    );

    // 2. Room semester price (annual price stays as price_pesewas)
    await queryRunner.query(
      `ALTER TABLE rooms ADD COLUMN IF NOT EXISTS price_per_semester_pesewas BIGINT`
    );

    // 3. Backfill semester price as annual / 2 + 10% premium
    await queryRunner.query(
      `UPDATE rooms SET price_per_semester_pesewas = ROUND(price_pesewas * 0.55) WHERE price_per_semester_pesewas IS NULL`
    );

    // 4. Booking duration
    await queryRunner.query(
      `ALTER TABLE bookings ADD COLUMN IF NOT EXISTS duration VARCHAR(20) NOT NULL DEFAULT 'FULL_YEAR'`
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE bookings DROP COLUMN IF EXISTS duration`);
    await queryRunner.query(`ALTER TABLE rooms DROP COLUMN IF EXISTS price_per_semester_pesewas`);
    await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS booking_mode`);
  }
}
