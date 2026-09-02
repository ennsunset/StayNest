"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExpandRoomTypes1724700000000 = void 0;
class ExpandRoomTypes1724700000000 {
    async up(runner) {
        await runner.query(`ALTER TYPE room_type ADD VALUE IF NOT EXISTS '5-in-a-room'`);
        await runner.query(`ALTER TYPE room_type ADD VALUE IF NOT EXISTS '6-in-a-room'`);
        await runner.query(`ALTER TYPE room_type ADD VALUE IF NOT EXISTS '7-in-a-room'`);
        await runner.query(`ALTER TYPE room_type ADD VALUE IF NOT EXISTS '8-in-a-room'`);
        await runner.query(`ALTER TABLE rooms ADD COLUMN IF NOT EXISTS has_fan BOOLEAN NOT NULL DEFAULT false`);
        await runner.query(`ALTER TABLE rooms ADD COLUMN IF NOT EXISTS socket_count INT NOT NULL DEFAULT 1`);
    }
    async down(runner) {
        await runner.query(`ALTER TABLE rooms DROP COLUMN IF EXISTS has_fan`);
        await runner.query(`ALTER TABLE rooms DROP COLUMN IF EXISTS socket_count`);
    }
}
exports.ExpandRoomTypes1724700000000 = ExpandRoomTypes1724700000000;
//# sourceMappingURL=1724700000000-ExpandRoomTypes.js.map