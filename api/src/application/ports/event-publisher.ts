import type { Payment } from "../../domain/entities/payment";

export interface EventPublisher {
  publish(payment: Payment): Promise<PublishResult>;
}

export interface PublishResult {
  messageId: string;
}
