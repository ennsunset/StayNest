// src/payments/payments.controller.ts

import {
  Controller, Post, Get, Body, Param, Req, Res,
  UseGuards, Headers, RawBodyRequest, HttpCode,
  ParseUUIDPipe, BadRequestException, Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { PaymentsService } from './payments.service';
import { PaystackProvider } from './paystack.provider';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/roles.guard';
import { UserRole } from '../users/entities/user.entity';
import { InitializePaymentDto } from './payments.dto';

@Controller('payments')
export class PaymentsController {
  private readonly logger = new Logger(PaymentsController.name);

  constructor(
    private readonly payments: PaymentsService,
    private readonly paystack: PaystackProvider,
  ) {}

  
  /** Student payment history */
  @Get('my-history')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.STUDENT)
  getMyHistory(@Req() req: any) {
    return this.payments.getStudentHistory(req.user.sub);
  }

  /** Initialize payment for a booking */
  @Post('initialize')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.STUDENT)
  initialize(@Req() req: any, @Body() dto: InitializePaymentDto) {
    return this.payments.initializePayment(
      dto.bookingId,
      req.user.sub,
      req.user.email,
      dto.callbackUrl,
      dto.installmentId,
    );
  }

  /**
   * Paystack webhook — NO auth guard.
   * - Immediate 200 response
   * - HMAC-SHA512 verification
   * - Async processing
   */
  @Post('webhook/paystack')
  @HttpCode(200)
  async paystackWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('x-paystack-signature') signature: string,
  ) {
    // 1. Get raw body for HMAC
    const rawBody = req.rawBody?.toString('utf-8');
    if (!rawBody) {
      this.logger.warn('Webhook received without raw body');
      return { received: true };
    }

    // 2. Validate HMAC-SHA512 signature
    if (!signature || !this.paystack.validateWebhook(rawBody, signature)) {
      this.logger.warn('Invalid webhook signature');
      return { received: true }; // Still 200 — don't leak validation info
    }

    // 3. Parse and process asynchronously (don't block the 200)
    const payload = JSON.parse(rawBody);
    this.logger.log(`Webhook received: ${payload.event} for ${payload.data?.reference}`);

    // Fire and forget — errors are caught inside handleWebhook
    this.payments.handleWebhook(payload.event, payload.data).catch((err) => {
      this.logger.error(`Webhook processing error: ${err.message}`);
    });

    return { received: true };
  }

  /** Client-side verify after redirect */
  @Get('verify/:reference')
  @UseGuards(JwtAuthGuard)
  verify(@Param('reference') reference: string) {
    return this.payments.verifyPayment(reference);
  }
}
