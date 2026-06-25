type ParseJsonBodyResult =
  | { ok: true; value: unknown }
  | { ok: false; message: string };

export function parseJsonBody(body: string | undefined): ParseJsonBodyResult {
  if (!body) {
    return {
      ok: false,
      message: "O corpo da requisicao e obrigatorio",
    };
  }

  try {
    return {
      ok: true,
      value: JSON.parse(body),
    };
  } catch {
    return {
      ok: false,
      message: "O corpo da requisicao deve ser um JSON valido",
    };
  }
}
