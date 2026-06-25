# Payment Microservice

[![Deploy Lambda](https://github.com/kaiotcp1/payment-microservice/actions/workflows/deploy-lambda.yml/badge.svg)](https://github.com/kaiotcp1/payment-microservice/actions/workflows/deploy-lambda.yml)
![Node.js](https://img.shields.io/badge/node.js-22.x-339933)
![TypeScript](https://img.shields.io/badge/typescript-strict-3178c6)
![Terraform](https://img.shields.io/badge/terraform-1.9%2B-7b42bc)
![AWS](https://img.shields.io/badge/aws-lambda%20%7C%20sns%20%7C%20sqs%20%7C%20apigateway-ff9900)

Microservico de pagamentos assincromo usando AWS Lambda, API Gateway, SNS e SQS.
O objetivo e demonstrar uma arquitetura simples, limpa e deployavel com
Terraform e GitHub Actions.

## Intuito

Este projeto foi criado para estudar e praticar:

- Clean Architecture em uma Lambda TypeScript sem excesso de abstracoes.
- Infraestrutura como codigo com Terraform.
- Deploy automatizado com GitHub Actions e OIDC.
- Fluxo event-driven com SNS e SQS.
- Separacao clara entre bootstrap de CI/CD e stack da aplicacao.

## Arquitetura

```text
Client
  -> API Gateway HTTP API
  -> Lambda Producer
  -> SNS Topic
  -> SQS Queue
  -> SQS DLQ
```

Camadas da Lambda:

```text
main.ts
  -> factories
  -> presentation/http
  -> application
  -> domain

infra/adapters
  -> application/ports
  -> domain
```

## Stack

- **Runtime**: Node.js 22
- **Language**: TypeScript
- **Validation**: Zod
- **Logging**: Pino
- **Cloud**: AWS Lambda, API Gateway, SNS, SQS, CloudWatch, IAM
- **IaC**: Terraform
- **CI/CD**: GitHub Actions with AWS OIDC

## Estrutura

```text
api/
  src/
    application/
    domain/
    factories/
    infra/
    presentation/
terraform/
  Application infrastructure
terraform-bootstrap/
  CI/CD bootstrap infrastructure
docs/
  deploy-pipeline.md
.github/workflows/
  deploy-lambda.yml
```

## Como Rodar Localmente

Instale dependencias:

```bash
cd api
npm install
```

Valide TypeScript:

```bash
npm run typecheck
```

Gere o bundle da Lambda:

```bash
npm run build
```

## Bootstrap Do Deploy

Antes da pipeline funcionar, rode o bootstrap uma vez na sua maquina:

```bash
cd terraform-bootstrap
cp terraform.tfvars.example terraform.tfvars
```

No PowerShell:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edite:

```hcl
github_owner      = "kaiotcp1"
github_repository = "payment-microservice"
```

Aplique:

```bash
terraform init
terraform plan
terraform apply
```

Depois configure os outputs no GitHub Actions.

Guia completo:

[Deploy Pipeline](docs/deploy-pipeline.md)

## Deploy

O deploy roda quando um PR de uma branch `feature/*` e mergeado em `main`.

Fluxo:

```bash
git checkout -b feature/test-pipeline
git add .
git commit -m "test deployment pipeline"
git push -u origin feature/test-pipeline
```

Depois abra PR para `main` e faca merge.

## Endpoint

Depois do deploy, a API exposta pelo output `api_url_post` aceita:

```http
POST /payment
```

Payload:

```json
{
  "amount": 150.99,
  "beneficiary": "Loja Online LTDA",
  "pixKey": "loja@pix.com",
  "description": "Compra de notebook"
}
```

Resposta esperada:

```json
{
  "message": "Pagamento recebido e encaminhado para processamento",
  "idempotencyKey": "uuid",
  "messageId": "sns-message-id"
}
```

## Comandos Uteis

Typecheck:

```bash
cd api
npm run typecheck
```

Build:

```bash
cd api
npm run build
```

Validar Terraform da aplicacao:

```bash
cd terraform
terraform fmt -check -recursive
terraform validate
```

Validar bootstrap:

```bash
cd terraform-bootstrap
terraform fmt -check -recursive
terraform validate
```

## Documentacao

- [Deploy Pipeline](docs/deploy-pipeline.md)
- [Terraform Bootstrap](terraform-bootstrap/README.md)
- [Workflow GitHub Actions](.github/workflows/deploy-lambda.yml)

## Observacoes

- O bootstrap usa `AdministratorAccess` por padrao para simplificar o ambiente de
  estudo/dev. Para producao, reduza as permissoes da role.
- O state da aplicacao fica em S3; o bootstrap usa state local.
