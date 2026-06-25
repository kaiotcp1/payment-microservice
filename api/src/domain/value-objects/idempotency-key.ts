import { randomUUID } from "node:crypto";

export class IdempotencyKey {
  private constructor(public readonly value: string) {}

  static generate(): IdempotencyKey {
    return new IdempotencyKey(randomUUID());
  }

  static from(value: string): IdempotencyKey {
    if (!value || value.length === 0) {
      throw new Error("Idempotency key cannot be empty");
    }

    return new IdempotencyKey(value);
  }

  equals(other: IdempotencyKey): boolean {
    return this.value === other.value;
  }

  toString(): string {
    return this.value;
  }
}
