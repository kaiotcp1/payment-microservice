import { existsSync, mkdirSync } from "node:fs";
import { createRequire } from "node:module";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, "..");
const LAMBDA_DIR = resolve(ROOT, "api");
const DIST_DIR = resolve(LAMBDA_DIR, "dist");

const lambdaRequire = createRequire(resolve(LAMBDA_DIR, "package.json"));
const esbuild = lambdaRequire("esbuild");
const { build, analyzeMetafile } = esbuild;

if (!existsSync(DIST_DIR)) {
  mkdirSync(DIST_DIR, { recursive: true });
}

console.log(`[build] Iniciando build da Lambda...`);
console.log(`[build] Source: ${LAMBDA_DIR}/src/main.ts`);
console.log(`[build] Target: ${DIST_DIR}/main.mjs`);

try {
  const result = await build({
    entryPoints: [resolve(LAMBDA_DIR, "src/main.ts")],
    outfile: resolve(DIST_DIR, "main.mjs"),
    bundle: true,
    minify: false,
    sourcemap: true,
    platform: "node",
    target: "node22",
    format: "esm",
    external: ["@aws-sdk/*"],
    treeShaking: true,
    metafile: true,
  });

  const analysis = await analyzeMetafile(result.metafile);
  console.log(analysis);

  console.log(`[build] Build concluido com sucesso!`);
  console.log(`[build]   Arquivo: ${DIST_DIR}/main.mjs`);
} catch (error) {
  console.error("[build] Erro no build:", error);
  process.exit(1);
}
