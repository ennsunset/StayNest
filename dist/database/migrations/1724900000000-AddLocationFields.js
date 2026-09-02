"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddLocationFields1724900000000 = void 0;
class AddLocationFields1724900000000 {
    async up(queryRunner) {
        await queryRunner.query(`
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS region VARCHAR(100);
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS area VARCHAR(200);
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS landmark VARCHAR(300);
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS digital_address VARCHAR(50);
    `);
    }
    async down(queryRunner) {
        await queryRunner.query(`
      ALTER TABLE hostels DROP COLUMN IF EXISTS region;
      ALTER TABLE hostels DROP COLUMN IF EXISTS area;
      ALTER TABLE hostels DROP COLUMN IF EXISTS landmark;
      ALTER TABLE hostels DROP COLUMN IF EXISTS digital_address;
    `);
    }
}
exports.AddLocationFields1724900000000 = AddLocationFields1724900000000;
//# sourceMappingURL=1724900000000-AddLocationFields.js.map