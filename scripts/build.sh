#!/bin/bash
set -euo pipefail

echo "========================================="
echo " Build da Lambda Producer"
echo "========================================="

cd "$(dirname "$0")/../api"

if [ ! -d "node_modules" ]; then
  echo "[1/3] Instalando dependencias npm..."
  npm install --production=false
fi

echo "[2/3] Verificando tipos TypeScript..."
npx tsc --noEmit
echo "Tipos OK"

echo "[3/3] Gerando bundle com esbuild..."
node ../scripts/build.js

echo ""
echo "========================================="
echo " Build concluido!"
echo " Bundle: api/dist/main.js"
echo "========================================="
