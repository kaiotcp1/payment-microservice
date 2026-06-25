import type { Payment } from "../../domain/entities/payment";
import { IdempotencyKey } from "../../domain/value-objects/idempotency-key";
import type {
  ProcessPaymentInput,
  ProcessPaymentOutput,
} from "../dtos/process-payment-dto";
import { ProcessPaymentError } from "../errors/application-error";
import type { EventPublisher } from "../ports/event-publisher";

export class ProcessPaymentUseCase {
  constructor(private readonly eventPublisher: EventPublisher) {}

  async execute(input: ProcessPaymentInput): Promise<ProcessPaymentOutput> {
    const idempotencyKey = IdempotencyKey.generate();

    const payment: Payment = {
      idempotencyKey: idempotencyKey.value,
      amount: input.amount,
      beneficiary: input.beneficiary,
      pixKey: input.pixKey,
      description: input.description,
      timestamp: new Date().toISOString(),
      type: "payment.pix",
    };

    try {
      const result = await this.eventPublisher.publish(payment);

      return {
        payment,
        messageId: result.messageId,
      };
    } catch (error) {
      throw new ProcessPaymentError(
        "Falha ao processar pagamento no barramento de eventos",
        error
      );
    }
  }
}
