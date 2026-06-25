#!/bin/bash
set -euo pipefail

echo "========================================="
echo " Deploy do Payment Microservice"
echo "========================================="

echo ""
echo "[1/3] Build da Lambda..."
bash scripts/build.sh

echo ""
echo "[2/3] Terraform Init..."
cd terraform

if [ ! -d ".terraform" ]; then
  terraform init
else
  terraform init -upgrade
fi

echo ""
echo "[3/3] Terraform Plan & Apply..."
terraform fmt -recursive
terraform validate

echo ""
echo "--- Terraform Plan ---"
terraform plan -out=tfplan

echo ""
read -p "Aplicar as mudancas acima? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  terraform apply tfplan

  echo ""
  echo "========================================="
  echo " Deploy concluido!"
  echo "========================================="
  echo ""
  echo "URL da API:"
  terraform output api_url_post
else
  echo "Deploy cancelado."
fi
