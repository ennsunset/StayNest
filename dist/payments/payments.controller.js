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
var PaymentsController_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsController = void 0;
const common_1 = require("@nestjs/common");
const payments_service_1 = require("./payments.service");
const paystack_provider_1 = require("./paystack.provider");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const roles_guard_1 = require("../auth/roles.guard");
const user_entity_1 = require("../users/entities/user.entity");
const payments_dto_1 = require("./payments.dto");
let PaymentsController = PaymentsController_1 = class PaymentsController {
    constructor(payments, paystack) {
        this.payments = payments;
        this.paystack = paystack;
        this.logger = new common_1.Logger(PaymentsController_1.name);
    }
    getMyHistory(req) {
        return this.payments.getStudentHistory(req.user.sub);
    }
    initialize(req, dto) {
        return this.payments.initializePayment(dto.bookingId, req.user.sub, req.user.email, dto.callbackUrl, dto.installmentId);
    }
    async paystackWebhook(req, signature) {
        const rawBody = req.rawBody?.toString('utf-8');
        if (!rawBody) {
            this.logger.warn('Webhook received without raw body');
            return { received: true };
        }
        if (!signature || !this.paystack.validateWebhook(rawBody, signature)) {
            this.logger.warn('Invalid webhook signature');
            return { received: true };
        }
        const payload = JSON.parse(rawBody);
        this.logger.log(`Webhook received: ${payload.event} for ${payload.data?.reference}`);
        this.payments.handleWebhook(payload.event, payload.data).catch((err) => {
            this.logger.error(`Webhook processing error: ${err.message}`);
        });
        return { received: true };
    }
    verify(reference) {
        return this.payments.verifyPayment(reference);
    }
};
exports.PaymentsController = PaymentsController;
__decorate([
    (0, common_1.Get)('my-history'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.STUDENT),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], PaymentsController.prototype, "getMyHistory", null);
__decorate([
    (0, common_1.Post)('initialize'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.STUDENT),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, payments_dto_1.InitializePaymentDto]),
    __metadata("design:returntype", void 0)
], PaymentsController.prototype, "initialize", null);
__decorate([
    (0, common_1.Post)('webhook/paystack'),
    (0, common_1.HttpCode)(200),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Headers)('x-paystack-signature')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], PaymentsController.prototype, "paystackWebhook", null);
__decorate([
    (0, common_1.Get)('verify/:reference'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('reference')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PaymentsController.prototype, "verify", null);
exports.PaymentsController = PaymentsController = PaymentsController_1 = __decorate([
    (0, common_1.Controller)('payments'),
    __metadata("design:paramtypes", [payments_service_1.PaymentsService,
        paystack_provider_1.PaystackProvider])
], PaymentsController);
//# sourceMappingURL=payments.controller.js.map