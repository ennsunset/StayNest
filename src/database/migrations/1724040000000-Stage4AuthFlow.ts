import { MigrationInterface, QueryRunner } from 'typeorm';

export class Stage4AuthFlow1724040000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Add new columns to users table
    await queryRunner.query(`
      ALTER TABLE users
        ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
        ADD COLUMN IF NOT EXISTS university VARCHAR(100),
        ADD COLUMN IF NOT EXISTS level VARCHAR(20),
        ADD COLUMN IF NOT EXISTS interests TEXT[] DEFAULT '{}',
        ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN NOT NULL DEFAULT false,
        ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false,
        ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN NOT NULL DEFAULT false
    `);

    // Create verification_codes table
    await queryRunner.query(`
      CREATE TYPE verification_code_type AS ENUM ('PHONE', 'EMAIL');

      CREATE TABLE verification_codes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        code VARCHAR(6) NOT NULL,
        type verification_code_type NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL,
        used BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE INDEX idx_verification_codes_user_type
        ON verification_codes (user_id, type)
        WHERE used = false;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS verification_codes`);
    await queryRunner.query(`DROP TYPE IF EXISTS verification_code_type`);
    await queryRunner.query(`
      ALTER TABLE users
        DROP COLUMN IF EXISTS phone,
        DROP COLUMN IF EXISTS university,
        DROP COLUMN IF EXISTS level,
        DROP COLUMN IF EXISTS interests,
        DROP COLUMN IF EXISTS phone_verified,
        DROP COLUMN IF EXISTS email_verified,
        DROP COLUMN IF EXISTS profile_completed
    `);
  }
}
