import type { APIGatewayProxyResultV2 } from "aws-lambda";

const JSON_HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Idempotency-Key",
};

export function emptyResponse(statusCode: number): APIGatewayProxyResultV2 {
  return {
    statusCode,
    headers: JSON_HEADERS,
  };
}

export function jsonResponse(
  statusCode: number,
  body: unknown
): APIGatewayProxyResultV2 {
  return {
    statusCode,
    headers: JSON_HEADERS,
    body: JSON.stringify(body),
  };
}

export function errorResponse(
  statusCode: number,
  error: string,
  message: string,
  details?: unknown
): APIGatewayProxyResultV2 {
  return jsonResponse(statusCode, {
    error,
    message,
    ...(details === undefined ? {} : { details }),
  });
}
