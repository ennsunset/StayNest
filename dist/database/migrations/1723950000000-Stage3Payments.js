"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Stage3Payments1723950000000 = void 0;
class Stage3Payments1723950000000 {
    async up(queryRunner) {
        await queryRunner.query(`
      CREATE TYPE payment_status AS ENUM (
        'PENDING', 'SUCCESS', 'FAILED', 'ABANDONED', 'REFUNDED'
      );
    `);
        await queryRunner.query(`
      CREATE TYPE payment_channel AS ENUM (
        'MOBILE_MONEY', 'CARD', 'BANK', 'USSD'
      );
    `);
        await queryRunner.query(`
      CREATE TABLE payments (
        id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        booking_id      UUID NOT NULL REFERENCES bookings(id),
        provider_reference VARCHAR(100) NOT NULL,
        provider_id     VARCHAR(100),
        status          payment_status NOT NULL DEFAULT 'PENDING',
        amount_pesewas  BIGINT NOT NULL,
        currency        VARCHAR(3) NOT NULL DEFAULT 'GHS',
        channel         payment_channel,
        provider_meta   JSONB,
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
        await queryRunner.query(`
      CREATE UNIQUE INDEX idx_payments_provider_ref ON payments(provider_reference);
    `);
        await queryRunner.query(`
      CREATE INDEX idx_payments_booking_id ON payments(booking_id);
    `);
        await queryRunner.query(`
      CREATE INDEX idx_payments_status ON payments(status);
    `);
    }
    async down(queryRunner) {
        await queryRunner.query(`DROP TABLE IF EXISTS payments CASCADE;`);
        await queryRunner.query(`DROP TYPE IF EXISTS payment_channel;`);
        await queryRunner.query(`DROP TYPE IF EXISTS payment_status;`);
    }
}
exports.Stage3Payments1723950000000 = Stage3Payments1723950000000;
//# sourceMappingURL=1723950000000-Stage3Payments.js.map