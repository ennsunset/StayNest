// src/payments/paystack.provider.ts

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';
import { IPaymentProvider, InitializeResult, VerifyResult } from './payment-provider.interface';

@Injectable()
export class PaystackProvider implements IPaymentProvider {
  private readonly logger = new Logger(PaystackProvider.name);
  private readonly secretKey: string;
  private readonly baseUrl = 'https://api.paystack.co';

  constructor(private readonly config: ConfigService) {
    this.secretKey = this.config.getOrThrow<string>('PAYSTACK_SECRET_KEY');
  }

  async initialize(params: {
    reference: string;
    amountPesewas: number;
    email: string;
    currency?: string;
    callbackUrl?: string;
    metadata?: Record<string, any>;
  }): Promise<InitializeResult> {
    const res = await fetch(`${this.baseUrl}/transaction/initialize`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        reference: params.reference,
        amount: params.amountPesewas, // Paystack expects pesewas/kobo
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

  async verify(reference: string): Promise<VerifyResult> {
    const res = await fetch(
      `${this.baseUrl}/transaction/verify/${encodeURIComponent(reference)}`,
      {
        headers: { Authorization: `Bearer ${this.secretKey}` },
      },
    );

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

  validateWebhook(body: string, signature: string): boolean {
    const hash = createHmac('sha512', this.secretKey)
      .update(body)
      .digest('hex');
    return hash === signature;
  }
}
