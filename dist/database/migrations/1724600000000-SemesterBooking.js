"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SemesterBooking1724600000000 = void 0;
class SemesterBooking1724600000000 {
    async up(queryRunner) {
        await queryRunner.query(`ALTER TABLE hostels ADD COLUMN IF NOT EXISTS booking_mode VARCHAR(20) NOT NULL DEFAULT 'FLEXIBLE'`);
        await queryRunner.query(`ALTER TABLE rooms ADD COLUMN IF NOT EXISTS price_per_semester_pesewas BIGINT`);
        await queryRunner.query(`UPDATE rooms SET price_per_semester_pesewas = ROUND(price_pesewas * 0.55) WHERE price_per_semester_pesewas IS NULL`);
        await queryRunner.query(`ALTER TABLE bookings ADD COLUMN IF NOT EXISTS duration VARCHAR(20) NOT NULL DEFAULT 'FULL_YEAR'`);
    }
    async down(queryRunner) {
        await queryRunner.query(`ALTER TABLE bookings DROP COLUMN IF EXISTS duration`);
        await queryRunner.query(`ALTER TABLE rooms DROP COLUMN IF EXISTS price_per_semester_pesewas`);
        await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS booking_mode`);
    }
}
exports.SemesterBooking1724600000000 = SemesterBooking1724600000000;
//# sourceMappingURL=1724600000000-SemesterBooking.js.map