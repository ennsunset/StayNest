"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CommunityService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("typeorm");
let CommunityService = class CommunityService {
    constructor(dataSource) {
        this.dataSource = dataSource;
    }
    async createPost(studentId, hostelId, dto) {
        const [booking] = await this.dataSource.query(`SELECT b.id FROM bookings b
       JOIN beds bed ON bed.id = b.bed_id
       JOIN rooms r ON r.id = bed.room_id
       JOIN floors f ON f.id = r.floor_id
       JOIN buildings bld ON bld.id = f.building_id
       WHERE b.student_id = $1 AND bld.hostel_id = $2 AND b.status = 'CHECKED_IN'
       LIMIT 1`, [studentId, hostelId]);
        if (!booking)
            throw new common_1.ForbiddenException('You must be a current resident to post');
        const [post] = await this.dataSource.query(`INSERT INTO community_posts (hostel_id, student_id, category, title, body, image_url, price_pesewas)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`, [hostelId, studentId, dto.category, dto.title, dto.body, dto.imageUrl || null, dto.pricePesewas || null]);
        return post;
    }
    async getPosts(hostelId, category, limit = 50, offset = 0) {
        let query = `SELECT cp.*, u.full_name AS author_name, u.avatar_url AS author_avatar
       FROM community_posts cp
       JOIN users u ON u.id = cp.student_id
       WHERE cp.hostel_id = $1 AND cp.status = 'ACTIVE'`;
        const params = [hostelId];
        if (category && category !== 'ALL') {
            params.push(category);
            query += ` AND cp.category = $${params.length}`;
        }
        params.push(limit, offset);
        query += ` ORDER BY cp.created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`;
        return this.dataSource.query(query, params);
    }
    async deletePost(postId, studentId) {
        const [post] = await this.dataSource.query(`SELECT * FROM community_posts WHERE id = $1`, [postId]);
        if (!post)
            throw new common_1.NotFoundException('Post not found');
        if (post.student_id !== studentId)
            throw new common_1.ForbiddenException('Not your post');
        await this.dataSource.query(`UPDATE community_posts SET status = 'DELETED', updated_at = NOW() WHERE id = $1`, [postId]);
        return { success: true };
    }
    async markSold(postId, studentId) {
        const [post] = await this.dataSource.query(`SELECT * FROM community_posts WHERE id = $1`, [postId]);
        if (!post)
            throw new common_1.NotFoundException('Post not found');
        if (post.student_id !== studentId)
            throw new common_1.ForbiddenException('Not your post');
        await this.dataSource.query(`UPDATE community_posts SET status = 'SOLD', updated_at = NOW() WHERE id = $1`, [postId]);
        return { success: true };
    }
};
exports.CommunityService = CommunityService;
exports.CommunityService = CommunityService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeorm_1.DataSource])
], CommunityService);
//# sourceMappingURL=community.service.js.map