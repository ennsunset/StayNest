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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const users_service_1 = require("../users/users.service");
const verification_code_entity_1 = require("./entities/verification-code.entity");
const google_auth_library_1 = require("google-auth-library");
const sms_service_1 = require("../common/services/sms.service");
const email_service_1 = require("../common/services/email.service");
let AuthService = class AuthService {
    constructor(users, jwt, config, codesRepo, sms, email) {
        this.users = users;
        this.jwt = jwt;
        this.config = config;
        this.codesRepo = codesRepo;
        this.sms = sms;
        this.email = email;
    }
    async register(data) {
        const user = await this.users.create(data);
        const tokens = await this.generateTokens(user);
        return { user: this.sanitize(user), tokens };
    }
    async login(email, password) {
        const user = await this.users.findByEmail(email);
        if (!user || !user.isActive) {
            throw new common_1.UnauthorizedException('Invalid credentials');
        }
        const valid = await this.users.validatePassword(user, password);
        if (!valid) {
            throw new common_1.UnauthorizedException('Invalid credentials');
        }
        const tokens = await this.generateTokens(user);
        return { user: this.sanitize(user), tokens };
    }
    async refresh(userId) {
        const user = await this.users.findById(userId);
        if (!user || !user.isActive) {
            throw new common_1.UnauthorizedException('User not found or inactive');
        }
        return this.generateTokens(user);
    }
    async sendOtp(userId, dto) {
        const user = await this.users.findById(userId);
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        if (dto.type === verification_code_entity_1.VerificationCodeType.PHONE && dto.phone) {
            await this.users.updatePhone(userId, dto.phone);
        }
        await this.codesRepo.update({ userId, type: dto.type, used: false }, { used: true });
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const verificationCode = this.codesRepo.create({
            userId,
            code,
            type: dto.type,
            expiresAt: new Date(Date.now() + 5 * 60 * 1000),
        });
        await this.codesRepo.save(verificationCode);
        if (dto.type === verification_code_entity_1.VerificationCodeType.PHONE) {
            const phone = dto.phone || user.phone;
            if (phone)
                await this.sms.send(phone, 'Your StayNest code is: ' + code);
        }
        else {
            await this.email.send(user.email, 'StayNest Verification Code', '<h2>Your verification code</h2><p style="font-size:32px;font-weight:bold;letter-spacing:8px">' + code + '</p><p>Expires in 5 minutes.</p>');
        }
        console.log('[OTP] Code for ' + user.email + ': ' + code);
        return { message: 'Verification code sent via ' + dto.type.toLowerCase() };
    }
    async verifyOtp(userId, dto) {
        const found = await this.codesRepo.findOne({
            where: { userId, type: dto.type, code: dto.code, used: false },
            order: { createdAt: 'DESC' },
        });
        if (!found) {
            throw new common_1.UnauthorizedException('Invalid verification code');
        }
        if (new Date() > found.expiresAt) {
            throw new common_1.UnauthorizedException('Verification code has expired');
        }
        found.used = true;
        await this.codesRepo.save(found);
        if (dto.type === verification_code_entity_1.VerificationCodeType.PHONE) {
            await this.users.markPhoneVerified(userId);
        }
        else {
            await this.users.markEmailVerified(userId);
        }
        return { verified: true };
    }
    async completeProfile(userId, dto) {
        return this.users.completeProfile(userId, dto);
    }
    async getVerificationStatus(userId) {
        const user = await this.users.findById(userId);
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        return {
            phoneVerified: user.phoneVerified,
            emailVerified: user.emailVerified,
            profileCompleted: user.profileCompleted,
            phone: user.phone,
            email: user.email,
        };
    }
    async generateTokens(user) {
        const payload = { sub: user.id, email: user.email, role: user.role };
        const [accessToken, refreshToken] = await Promise.all([
            this.jwt.signAsync(payload),
            this.jwt.signAsync(payload, {
                expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d'),
            }),
        ]);
        return { accessToken, refreshToken };
    }
    sanitize(user) {
        const { passwordHash, ...rest } = user;
        return rest;
    }
    async socialLogin(provider, idToken, fullName) {
        let email;
        let name;
        if (provider === 'google') {
            const clientId = this.config.get('GOOGLE_CLIENT_ID', '');
            const client = new google_auth_library_1.OAuth2Client(clientId);
            try {
                const ticket = await client.verifyIdToken({ idToken, audience: clientId });
                const payload = ticket.getPayload();
                if (!payload || !payload.email)
                    throw new common_1.UnauthorizedException('Invalid Google token');
                email = payload.email;
                name = payload.name || email.split('@')[0];
            }
            catch (e) {
                throw new common_1.UnauthorizedException('Google token verification failed');
            }
        }
        else if (provider === 'apple') {
            try {
                const parts = idToken.split('.');
                const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
                if (!payload.email)
                    throw new common_1.UnauthorizedException('Invalid Apple token');
                email = payload.email;
                name = fullName || email.split('@')[0];
            }
            catch (e) {
                throw new common_1.UnauthorizedException('Apple token verification failed');
            }
        }
        else {
            throw new common_1.BadRequestException('Unsupported provider');
        }
        let user = await this.users.findByEmail(email);
        if (!user) {
            user = await this.users.createSocialUser({ fullName: name, email, provider });
        }
        if (!user.isActive)
            throw new common_1.UnauthorizedException('Account is disabled');
        const tokens = await this.generateTokens(user);
        return { user: this.sanitize(user), tokens };
    }
    async forgotPassword(email) {
        const user = await this.users.findByEmail(email);
        if (!user)
            return { message: 'If that email is registered, a reset code has been sent.' };
        await this.codesRepo.update({ userId: user.id, type: verification_code_entity_1.VerificationCodeType.PASSWORD_RESET, used: false }, { used: true });
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const vc = this.codesRepo.create({
            userId: user.id,
            code,
            type: verification_code_entity_1.VerificationCodeType.PASSWORD_RESET,
            expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        });
        await this.codesRepo.save(vc);
        await this.email.send(email, 'StayNest Password Reset', '<h2>Password Reset Code</h2><p style="font-size:32px;font-weight:bold;letter-spacing:8px">' + code + '</p><p>Expires in 15 minutes.</p>');
        console.log('[RESET] Code for ' + email + ': ' + code);
        return { message: 'If that email is registered, a reset code has been sent.' };
    }
    async getMe(userId) {
        const user = await this.users.findById(userId);
        return { id: user.id, fullName: user.fullName, email: user.email, phone: user.phone, role: user.role, university: user.university, level: user.level, avatarUrl: user.avatarUrl, emailVerified: user.emailVerified, phoneVerified: user.phoneVerified, idVerified: user.idVerified, profileCompleted: user.profileCompleted, interests: user.interests };
    }
    async updateProfile(userId, data) {
        return this.users.updateProfile(userId, data);
    }
    async resetPassword(email, code, newPassword) {
        const user = await this.users.findByEmail(email);
        if (!user)
            throw new common_1.BadRequestException('Invalid code');
        const vc = await this.codesRepo.findOne({
            where: {
                userId: user.id,
                code,
                type: verification_code_entity_1.VerificationCodeType.PASSWORD_RESET,
                used: false,
            },
            order: { createdAt: 'DESC' },
        });
        if (!vc || vc.expiresAt < new Date()) {
            throw new common_1.BadRequestException('Invalid or expired code');
        }
        vc.used = true;
        await this.codesRepo.save(vc);
        await this.users.updatePassword(user.id, newPassword);
        return { message: 'Password reset successfully' };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __param(3, (0, typeorm_1.InjectRepository)(verification_code_entity_1.VerificationCode)),
    __metadata("design:paramtypes", [users_service_1.UsersService,
        jwt_1.JwtService,
        config_1.ConfigService,
        typeorm_2.Repository,
        sms_service_1.SmsService,
        email_service_1.EmailService])
], AuthService);
//# sourceMappingURL=auth.service.js.map