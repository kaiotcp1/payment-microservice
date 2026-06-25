export type PaymentType = "payment.pix";

export interface Payment {
  readonly idempotencyKey: string;
  readonly amount: number;
  readonly beneficiary: string;
  readonly pixKey?: string;
  readonly description?: string;
  readonly timestamp: string;
  readonly type: PaymentType;
}
