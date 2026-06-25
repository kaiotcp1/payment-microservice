import { PublishCommand, type SNSClient } from "@aws-sdk/client-sns";

import type {
  EventPublisher,
  PublishResult,
} from "../../application/ports/event-publisher";
import type { Payment } from "../../domain/entities/payment";
import type { AppLogger } from "../logger/pino-logger";

export class SnsEventPublisher implements EventPublisher {
  constructor(
    private readonly snsClient: SNSClient,
    private readonly topicArn: string,
    private readonly logger: AppLogger,
    private readonly source: string
  ) {}

  async publish(payment: Payment): Promise<PublishResult> {
    this.logger.info(
      { topicArn: this.topicArn, idempotencyKey: payment.idempotencyKey },
      "Publishing payment event to SNS"
    );

    try {
      const response = await this.snsClient.send(
        new PublishCommand({
          TopicArn: this.topicArn,
          Message: JSON.stringify(payment),
          MessageAttributes: {
            idempotencyKey: {
              DataType: "String",
              StringValue: payment.idempotencyKey,
            },
            type: {
              DataType: "String",
              StringValue: payment.type,
            },
            source: {
              DataType: "String",
              StringValue: this.source,
            },
            correlationId: {
              DataType: "String",
              StringValue: payment.idempotencyKey,
            },
          },
        })
      );

      const messageId = response.MessageId ?? "unknown";
      this.logger.info(
        { messageId, idempotencyKey: payment.idempotencyKey },
        "Payment event published to SNS"
      );

      return { messageId };
    } catch (error) {
      this.logger.error(
        { err: error, idempotencyKey: payment.idempotencyKey },
        "Failed to publish payment event to SNS"
      );
      throw error;
    }
  }
}
