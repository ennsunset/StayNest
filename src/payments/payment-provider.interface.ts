// src/payments/payment-provider.interface.ts

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
  /** Initialize a payment - returns a URL to redirect the user to */
  initialize(params: {
    reference: string;
    amountPesewas: number;
    email: string;
    currency?: string;
    callbackUrl?: string;
    metadata?: Record<string, any>;
  }): Promise<InitializeResult>;

  /** Server-side verify a transaction by reference */
  verify(reference: string): Promise<VerifyResult>;

  /** Validate webhook signature. Returns true if valid. */
  validateWebhook(body: string, signature: string): boolean;
}
