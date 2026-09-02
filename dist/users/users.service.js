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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const argon2 = require("argon2");
const user_entity_1 = require("./entities/user.entity");
let UsersService = class UsersService {
    constructor(repo) {
        this.repo = repo;
    }
    async findByEmail(email) {
        return this.repo.findOne({ where: { email: email.toLowerCase() } });
    }
    async findById(id) {
        return this.repo.findOne({ where: { id } });
    }
    async create(data) {
        const existing = await this.findByEmail(data.email);
        if (existing) {
            throw new common_1.ConflictException('Email already registered');
        }
        const passwordHash = await argon2.hash(data.password, {
            type: argon2.argon2id,
        });
        const user = this.repo.create({
            fullName: data.fullName,
            email: data.email.toLowerCase(),
            passwordHash,
            role: data.role ?? user_entity_1.UserRole.STUDENT,
            phone: data.phone ?? null,
            university: data.university ?? null,
            level: data.level ?? null,
        });
        return this.repo.save(user);
    }
    async validatePassword(user, password) {
        return argon2.verify(user.passwordHash, password);
    }
    async updatePhone(userId, phone) {
        await this.repo.update(userId, { phone });
    }
    async markPhoneVerified(userId) {
        await this.repo.update(userId, { phoneVerified: true });
    }
    async markEmailVerified(userId) {
        await this.repo.update(userId, { emailVerified: true });
    }
    async completeProfile(userId, dto) {
        await this.repo.update(userId, {
            ...dto,
            profileCompleted: true,
        });
        return this.findById(userId);
    }
    async updatePassword(userId, newPassword) {
        const passwordHash = await argon2.hash(newPassword, {
            type: argon2.argon2id,
            memoryCost: 65536,
            timeCost: 3,
            parallelism: 4,
        });
        await this.repo.update(userId, { passwordHash });
    }
    async updateProfile(userId, data) {
        const user = await this.repo.findOneBy({ id: userId });
        if (!user)
            throw new Error('User not found');
        if (data.fullName)
            user.fullName = data.fullName;
        if (data.phone)
            user.phone = data.phone;
        if (data.level)
            user.level = data.level;
        if (data.university)
            user.university = data.university;
        if (data.avatarUrl)
            user.avatarUrl = data.avatarUrl;
        await this.repo.save(user);
        return { id: user.id, fullName: user.fullName, email: user.email, phone: user.phone, role: user.role, university: user.university, level: user.level, avatarUrl: user.avatarUrl, emailVerified: user.emailVerified, phoneVerified: user.phoneVerified, idVerified: user.idVerified, profileCompleted: user.profileCompleted, interests: user.interests };
    }
    async createSocialUser(data) {
        const user = this.repo.create({
            fullName: data.fullName,
            email: data.email.toLowerCase(),
            passwordHash: 'SOCIAL_' + data.provider.toUpperCase(),
            role: user_entity_1.UserRole.STUDENT,
            emailVerified: true,
            isActive: true,
        });
        return this.repo.save(user);
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], UsersService);
//# sourceMappingURL=users.service.js.map