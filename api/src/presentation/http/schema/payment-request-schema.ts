import { z } from "zod";

export const PaymentRequestSchema = z
  .object({
    amount: z
      .number()
      .positive("O valor deve ser positivo")
      .max(999999.99, "O valor maximo e R$ 999.999,99"),
    beneficiary: z
      .string()
      .min(3, "Nome do beneficiario deve ter pelo menos 3 caracteres")
      .max(100, "Nome do beneficiario deve ter no maximo 100 caracteres"),
    pixKey: z
      .string()
      .min(3, "Chave PIX invalida")
      .max(77, "Chave PIX muito longa")
      .optional(),
    description: z
      .string()
      .max(200, "Descricao deve ter no maximo 200 caracteres")
      .optional(),
  })
  .strict();
