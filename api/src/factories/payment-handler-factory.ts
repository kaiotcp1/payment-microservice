import type {
  APIGatewayProxyEventV2,
  APIGatewayProxyResultV2,
} from "aws-lambda";

import { ProcessPaymentUseCase } from "../application/use-cases/process-payment";
import { loadConfig } from "../config/app-config";
import { SnsEventPublisher } from "../infra/adapters/sns-event-publisher";
import { createSnsClient } from "../infra/aws/sns-client";
import { createLogger } from "../infra/logger/pino-logger";
import { PaymentHttpHandler } from "../presentation/http/payment-handler";

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
