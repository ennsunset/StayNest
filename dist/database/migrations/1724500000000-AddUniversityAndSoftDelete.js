"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddUniversityAndSoftDelete1724500000000 = void 0;
class AddUniversityAndSoftDelete1724500000000 {
    async up(queryRunner) {
        await queryRunner.query(`ALTER TABLE hostels ADD COLUMN IF NOT EXISTS university VARCHAR(100)`);
        await queryRunner.query(`ALTER TABLE hostels ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION`);
        await queryRunner.query(`ALTER TABLE hostels ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION`);
        await queryRunner.query(`ALTER TABLE hostels ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ`);
        await queryRunner.query(`UPDATE hostels SET university = 'KNUST' WHERE university IS NULL`);
        await queryRunner.query(`UPDATE hostels SET latitude = ST_Y(location::geometry), longitude = ST_X(location::geometry) WHERE location IS NOT NULL AND latitude IS NULL`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_hostels_university ON hostels (university)`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_hostels_not_deleted ON hostels (id) WHERE deleted_at IS NULL`);
    }
    async down(queryRunner) {
        await queryRunner.query(`DROP INDEX IF EXISTS idx_hostels_not_deleted`);
        await queryRunner.query(`DROP INDEX IF EXISTS idx_hostels_university`);
        await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS deleted_at`);
        await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS longitude`);
        await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS latitude`);
        await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS university`);
    }
}
exports.AddUniversityAndSoftDelete1724500000000 = AddUniversityAndSoftDelete1724500000000;
//# sourceMappingURL=1724500000000-AddUniversityAndSoftDelete.js.map