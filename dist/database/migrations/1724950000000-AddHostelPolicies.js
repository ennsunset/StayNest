"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddHostelPolicies1724950000000 = void 0;
class AddHostelPolicies1724950000000 {
    async up(queryRunner) {
        await queryRunner.query(`
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS gate_closing_time TIME DEFAULT NULL;
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS check_out_time TIME DEFAULT NULL;
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS cancellation_policy VARCHAR(20) DEFAULT 'FLEXIBLE';
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS house_rules TEXT DEFAULT NULL;
    `);
    }
    async down(queryRunner) {
        await queryRunner.query(`
      ALTER TABLE hostels DROP COLUMN IF EXISTS gate_closing_time;
      ALTER TABLE hostels DROP COLUMN IF EXISTS check_out_time;
      ALTER TABLE hostels DROP COLUMN IF EXISTS cancellation_policy;
      ALTER TABLE hostels DROP COLUMN IF EXISTS house_rules;
    `);
    }
}
exports.AddHostelPolicies1724950000000 = AddHostelPolicies1724950000000;
//# sourceMappingURL=1724950000000-AddHostelPolicies.js.map