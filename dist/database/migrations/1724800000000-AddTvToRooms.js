"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddTvToRooms1724800000000 = void 0;
class AddTvToRooms1724800000000 {
    async up(runner) {
        await runner.query(`ALTER TABLE rooms ADD COLUMN IF NOT EXISTS has_tv BOOLEAN NOT NULL DEFAULT false`);
    }
    async down(runner) {
        await runner.query(`ALTER TABLE rooms DROP COLUMN IF EXISTS has_tv`);
    }
}
exports.AddTvToRooms1724800000000 = AddTvToRooms1724800000000;
//# sourceMappingURL=1724800000000-AddTvToRooms.js.map