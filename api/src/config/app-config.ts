export interface AppConfig {
  appName: string;
  environment: string;
  logLevel: string;
  snsTopicArn: string;
  region: string;
}

export class ConfigurationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ConfigurationError";
    Error.captureStackTrace(this, this.constructor);
  }
}

export function loadConfig(): AppConfig {
  const snsTopicArn = process.env["SNS_TOPIC_ARN"] ?? "";

  if (!snsTopicArn) {
    throw new ConfigurationError(
      "Variavel de ambiente SNS_TOPIC_ARN nao configurada"
    );
  }

  return {
    appName: process.env["APP_NAME"] ?? "payment-producer",
    environment: process.env["NODE_ENV"] ?? "development",
    logLevel: process.env["LOG_LEVEL"] ?? "info",
    snsTopicArn,
    region: process.env["AWS_REGION"] ?? "us-east-1",
  };
}
