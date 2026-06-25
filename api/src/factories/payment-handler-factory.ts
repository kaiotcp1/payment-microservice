import type {
  APIGatewayProxyEventV2,
  APIGatewayProxyResultV2,
} from "aws-lambda";

import { ProcessPaymentUseCase } from "../application/use-cases/process-payment.js";
import { loadConfig } from "../config/app-config.js";
import { SnsEventPublisher } from "../infra/adapters/sns-event-publisher.js";
import { createSnsClient } from "../infra/aws/sns-client.js";
import { createLogger } from "../infra/logger/pino-logger.js";
import { PaymentHttpHandler } from "../presentation/http/payment-handler.js";

export function makePaymentHandler(): (
  event: APIGatewayProxyEventV2
) => Promise<APIGatewayProxyResultV2> {
  const config = loadConfig();
  const logger = createLogger(config);
  const snsClient = createSnsClient(config.region);

  const eventPublisher = new SnsEventPublisher(
    snsClient,
    config.snsTopicArn,
    logger,
    config.appName
  );

  const processPayment = new ProcessPaymentUseCase(eventPublisher);
  const paymentHandler = new PaymentHttpHandler(processPayment, logger);

  return (event) => paymentHandler.handle(event);
}
