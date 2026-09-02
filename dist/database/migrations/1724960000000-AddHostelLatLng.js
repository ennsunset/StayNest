"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddHostelLatLng1724960000000 = void 0;
class AddHostelLatLng1724960000000 {
    async up(queryRunner) {
        await queryRunner.query(`
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION DEFAULT NULL;
      ALTER TABLE hostels ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION DEFAULT NULL;
    `);
    }
    async down(queryRunner) {
        await queryRunner.query(`
      ALTER TABLE hostels DROP COLUMN IF EXISTS latitude;
      ALTER TABLE hostels DROP COLUMN IF EXISTS longitude;
    `);
    }
}
exports.AddHostelLatLng1724960000000 = AddHostelLatLng1724960000000;
//# sourceMappingURL=1724960000000-AddHostelLatLng.js.map