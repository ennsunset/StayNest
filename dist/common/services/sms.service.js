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
exports.SmsService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
let SmsService = class SmsService {
    constructor(config) {
        this.config = config;
        this.clientId = config.get('HUBTEL_CLIENT_ID', '');
        this.clientSecret = config.get('HUBTEL_CLIENT_SECRET', '');
        this.senderId = config.get('HUBTEL_SENDER_ID', 'StayNest');
    }
    async send(to, message) {
        if (!this.clientId || !this.clientSecret) {
            console.log(`[SMS STUB] To: ${to} | Message: ${message}`);
            return true;
        }
        try {
            const auth = Buffer.from(`${this.clientId}:${this.clientSecret}`).toString('base64');
            const res = await fetch(`https://smsc.hubtel.com/v1/messages/send?clientid=${encodeURIComponent(this.clientId)}&clientsecret=${encodeURIComponent(this.clientSecret)}&from=${encodeURIComponent(this.senderId)}&to=${encodeURIComponent(to)}&content=${encodeURIComponent(message)}`, { method: 'GET' });
            const data = await res.json();
            console.log('[SMS] Hubtel response:', JSON.stringify(data));
            return res.ok;
        }
        catch (e) {
            console.error('[SMS] Hubtel error:', e);
            return false;
        }
    }
};
exports.SmsService = SmsService;
exports.SmsService = SmsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], SmsService);
//# sourceMappingURL=sms.service.js.map