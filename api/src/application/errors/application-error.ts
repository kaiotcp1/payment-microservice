export class ApplicationError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    options?: { cause?: unknown }
  ) {
    super(message, { cause: options?.cause });
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ProcessPaymentError extends ApplicationError {
  constructor(message: string, cause?: unknown) {
    super(message, "PROCESS_PAYMENT_ERROR", { cause });
  }
}
