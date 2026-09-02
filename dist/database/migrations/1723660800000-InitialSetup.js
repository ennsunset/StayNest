"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InitialSetup1723660800000 = void 0;
class InitialSetup1723660800000 {
    async up(queryRunner) {
        await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`);
        await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "postgis"`);
        await queryRunner.query(`
      CREATE TABLE audit_log (
        id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        actor_id        UUID,
        actor_role      VARCHAR(50),
        action          VARCHAR(100) NOT NULL,
        target_type     VARCHAR(100),
        target_id       UUID,
        before_state    JSONB,
        after_state     JSONB,
        reason          TEXT,
        ip              INET,
        request_id      UUID,
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);
        await queryRunner.query(`
      CREATE OR REPLACE FUNCTION prevent_audit_mutation()
      RETURNS TRIGGER AS $$
      BEGIN
        RAISE EXCEPTION 'audit_log is append-only: % not allowed', TG_OP;
      END;
      $$ LANGUAGE plpgsql
    `);
        await queryRunner.query(`
      CREATE TRIGGER audit_log_no_update
      BEFORE UPDATE ON audit_log
      FOR EACH ROW EXECUTE FUNCTION prevent_audit_mutation()
    `);
        await queryRunner.query(`
      CREATE TRIGGER audit_log_no_delete
      BEFORE DELETE ON audit_log
      FOR EACH ROW EXECUTE FUNCTION prevent_audit_mutation()
    `);
        await queryRunner.query(`
      CREATE INDEX idx_audit_log_target
      ON audit_log (target_type, target_id, created_at DESC)
    `);
        await queryRunner.query(`
      CREATE INDEX idx_audit_log_actor
      ON audit_log (actor_id, created_at DESC)
    `);
    }
    async down(queryRunner) {
        await queryRunner.query(`DROP TRIGGER IF EXISTS audit_log_no_delete ON audit_log`);
        await queryRunner.query(`DROP TRIGGER IF EXISTS audit_log_no_update ON audit_log`);
        await queryRunner.query(`DROP FUNCTION IF EXISTS prevent_audit_mutation`);
        await queryRunner.query(`DROP TABLE IF EXISTS audit_log`);
    }
}
exports.InitialSetup1723660800000 = InitialSetup1723660800000;
//# sourceMappingURL=1723660800000-InitialSetup.js.map