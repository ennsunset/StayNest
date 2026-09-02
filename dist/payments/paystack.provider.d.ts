import { ConfigService } from '@nestjs/config';
import { IPaymentProvider, InitializeResult, VerifyResult } from './payment-provider.interface';
export declare class PaystackProvider implements IPaymentProvider {
    private readonly config;
    private readonly logger;
    private readonly secretKey;
    private readonly baseUrl;
    constructor(config: ConfigService);
    initialize(params: {
        reference: string;
        amountPesewas: number;
        email: string;
        currency?: string;
        callbackUrl?: string;
        metadata?: Record<string, any>;
    }): Promise<InitializeResult>;
    verify(reference: string): Promise<VerifyResult>;
    validateWebhook(body: string, signature: string): boolean;
}
