import { RawBodyRequest } from '@nestjs/common';
import { Request } from 'express';
import { PaymentsService } from './payments.service';
import { PaystackProvider } from './paystack.provider';
import { InitializePaymentDto } from './payments.dto';
export declare class PaymentsController {
    private readonly payments;
    private readonly paystack;
    private readonly logger;
    constructor(payments: PaymentsService, paystack: PaystackProvider);
    getMyHistory(req: any): Promise<{
        totalPaidYearPesewas: number;
        payments: any;
    }>;
    initialize(req: any, dto: InitializePaymentDto): Promise<{
        paymentId: string;
        authorizationUrl: string;
        accessCode: string;
        reference: string;
    }>;
    paystackWebhook(req: RawBodyRequest<Request>, signature: string): Promise<{
        received: boolean;
    }>;
    verify(reference: string): Promise<import("./entities/payment.entity").Payment | null>;
}
