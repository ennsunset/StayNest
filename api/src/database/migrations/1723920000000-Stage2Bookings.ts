import { MigrationInterface, QueryRunner } from 'typeorm';

export class Stage2Bookings1723920000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Create bookings table
    await queryRunner.query(`
      CREATE TABLE bookings (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        student_id UUID NOT NULL REFERENCES users(id),
        bed_id UUID NOT NULL REFERENCES beds(id),
        status VARCHAR(20) NOT NULL DEFAULT 'HELD',
        reference VARCHAR(20) NOT NULL,
        price_pesewas BIGINT NOT NULL,
        platform_fee_pesewas BIGINT NOT NULL DEFAULT 0,
        total_pesewas BIGINT NOT NULL,
        held_until TIMESTAMPTZ,
        period_label VARCHAR(50) NOT NULL DEFAULT 'Full Academic Year',
        check_in_date DATE,
        cancel_reason TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 2. Indexes
    await queryRunner.query(`CREATE INDEX idx_bookings_student_id ON bookings (student_id);`);
    await queryRunner.query(`CREATE INDEX idx_bookings_bed_id ON bookings (bed_id);`);
    await queryRunner.query(`CREATE UNIQUE INDEX idx_bookings_reference ON bookings (reference);`);

    // 3. THE SEATBELT — partial unique index: one active booking per bed.
    // Application logic will eventually have a bug; this constraint won't.
    await queryRunner.query(`
      CREATE UNIQUE INDEX one_active_booking_per_bed
      ON bookings (bed_id)
      WHERE status IN ('HELD', 'PENDING_PAYMENT', 'CONFIRMED', 'CHECKED_IN');
    `);

    // 4. Index for the expiry job — find HELD bookings past their deadline
    await queryRunner.query(`
      CREATE INDEX idx_bookings_held_expiry
      ON bookings (held_until)
      WHERE status = 'HELD';
    `);

    // 5. Audit trigger for bookings (append-only audit_log)
    await queryRunner.query(`
      CREATE OR REPLACE FUNCTION audit_booking_changes() RETURNS trigger AS $$
      BEGIN
        INSERT INTO audit_log (actor_id, action, target_type, target_id, before_state, after_state)
        VALUES (
          COALESCE(NEW.student_id, OLD.student_id),
          TG_OP,
          'BOOKING',
          COALESCE(NEW.id, OLD.id),
          CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE row_to_json(OLD)::text END,
          CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE row_to_json(NEW)::text END
        );
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    await queryRunner.query(`
      CREATE TRIGGER trg_audit_bookings
      AFTER INSERT OR UPDATE ON bookings
      FOR EACH ROW
      EXECUTE FUNCTION audit_booking_changes();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TRIGGER IF EXISTS trg_audit_bookings ON bookings;`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS audit_booking_changes();`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_bookings_held_expiry;`);
    await queryRunner.query(`DROP INDEX IF EXISTS one_active_booking_per_bed;`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_bookings_reference;`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_bookings_bed_id;`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_bookings_student_id;`);
    await queryRunner.query(`DROP TABLE IF EXISTS bookings;`);
  }
}
