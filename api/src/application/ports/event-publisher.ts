import type { Payment } from "../../domain/entities/payment.js";

export interface EventPublisher {
  publish(payment: Payment): Promise<PublishResult>;
}

export interface PublishResult {
  messageId: string;
}
