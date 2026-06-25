import type {
  APIGatewayProxyEventV2,
  APIGatewayProxyResultV2,
} from "aws-lambda";

import { ApplicationError } from "../../application/errors/application-error.js";
import type { ProcessPaymentUseCase } from "../../application/use-cases/process-payment.js";
import type { AppLogger } from "../../infra/logger/pino-logger.js";
import {
  emptyResponse,
  errorResponse,
  jsonResponse,
} from "./http-response.js";
import { parseJsonBody } from "./helpers/parse-json-body.js";
import { PaymentRequestSchema } from "./schema/payment-request-schema.js";

export class PaymentHttpHandler {
  constructor(
    private readonly processPayment: ProcessPaymentUseCase,
    private readonly logger: AppLogger
  ) { }

  async handle(
    event: APIGatewayProxyEventV2
  ): Promise<APIGatewayProxyResultV2> {
    this.logger.info(
      {
        method: event.requestContext.http.method,
        path: event.rawPath,
        requestId: event.requestContext.requestId,
        sourceIp: event.requestContext.http.sourceIp,
        userAgent: event.requestContext.http.userAgent,
      },
      "Payment request received"
    );

    if (event.requestContext.http.method === "OPTIONS") {
      return emptyResponse(204);
    }

    if (event.requestContext.http.method !== "POST") {
      return errorResponse(
        405,
        "METHOD_NOT_ALLOWED",
        "Apenas POST e aceito nesta rota"
      );
    }

    const body = parseJsonBody(event.body);
    if (!body.ok) {
      return errorResponse(400, "BAD_REQUEST", body.message);
    }

    const parsed = PaymentRequestSchema.safeParse(body.value);
    if (!parsed.success) {
      const details = parsed.error.issues.map((issue) => ({
        field: issue.path.join("."),
        message: issue.message,
      }));

      this.logger.warn({ details }, "Payment request validation failed");

      return errorResponse(
        422,
        "VALIDATION_ERROR",
        "Dados de pagamento invalidos",
        details
      );
    }

    try {
      const result = await this.processPayment.execute(parsed.data);

      this.logger.info(
        {
          idempotencyKey: result.payment.idempotencyKey,
          messageId: result.messageId,
        },
        "Payment request accepted"
      );

      return jsonResponse(202, {
        message: "Pagamento recebido e encaminhado para processamento",
        idempotencyKey: result.payment.idempotencyKey,
        messageId: result.messageId,
      });
    } catch (error) {
      this.logger.error({ err: error }, "Payment request failed");

      if (error instanceof ApplicationError) {
        return errorResponse(500, error.code, error.message);
      }

      return errorResponse(
        500,
        "INTERNAL_ERROR",
        "Ocorreu um erro inesperado. Tente novamente."
      );
    }
  }
}
