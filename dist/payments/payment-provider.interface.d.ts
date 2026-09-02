export interface InitializeResult {
    authorizationUrl: string;
    accessCode: string;
    providerReference: string;
}
export interface VerifyResult {
    success: boolean;
    providerReference: string;
    providerId: string;
    amountPesewas: number;
    currency: string;
    channel: string;
    paidAt: string | null;
    meta: Record<string, any>;
}
export interface IPaymentProvider {
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
