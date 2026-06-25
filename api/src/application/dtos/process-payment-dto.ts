import type { Payment } from "../../domain/entities/payment";

export interface ProcessPaymentInput {
  amount: number;
  beneficiary: string;
  pixKey?: string;
  description?: string;
}

export interface ProcessPaymentOutput {
  payment: Payment;
  messageId: string;
}
