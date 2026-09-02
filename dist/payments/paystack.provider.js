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
var PaystackProvider_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaystackProvider = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const crypto_1 = require("crypto");
let PaystackProvider = PaystackProvider_1 = class PaystackProvider {
    constructor(config) {
        this.config = config;
        this.logger = new common_1.Logger(PaystackProvider_1.name);
        this.baseUrl = 'https://api.paystack.co';
        this.secretKey = this.config.getOrThrow('PAYSTACK_SECRET_KEY');
    }
    async initialize(params) {
        const res = await fetch(`${this.baseUrl}/transaction/initialize`, {
            method: 'POST',
            headers: {
                Authorization: `Bearer ${this.secretKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                reference: params.reference,
                amount: params.amountPesewas,
                email: params.email,
                currency: params.currency ?? 'GHS',
                callback_url: params.callbackUrl,
                metadata: params.metadata,
                channels: ['mobile_money', 'card', 'bank'],
            }),
        });
        const data = await res.json();
        if (!data.status) {
            this.logger.error('Paystack initialize failed', data);
            throw new Error(data.message ?? 'Payment initialization failed');
        }
        return {
            authorizationUrl: data.data.authorization_url,
            accessCode: data.data.access_code,
            providerReference: data.data.reference,
        };
    }
    async verify(reference) {
        const res = await fetch(`${this.baseUrl}/transaction/verify/${encodeURIComponent(reference)}`, {
            headers: { Authorization: `Bearer ${this.secretKey}` },
        });
        const data = await res.json();
        if (!data.status) {
            this.logger.error('Paystack verify failed', data);
            throw new Error(data.message ?? 'Payment verification failed');
        }
        const tx = data.data;
        return {
            success: tx.status === 'success',
            providerReference: tx.reference,
            providerId: String(tx.id),
            amountPesewas: tx.amount,
            currency: tx.currency,
            channel: tx.channel,
            paidAt: tx.paid_at,
            meta: tx,
        };
    }
    validateWebhook(body, signature) {
        const hash = (0, crypto_1.createHmac)('sha512', this.secretKey)
            .update(body)
            .digest('hex');
        return hash === signature;
    }
};
exports.PaystackProvider = PaystackProvider;
exports.PaystackProvider = PaystackProvider = PaystackProvider_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], PaystackProvider);
//# sourceMappingURL=paystack.provider.js.map