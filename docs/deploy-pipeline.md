# Deploy Pipeline

Este documento explica como o deploy deste projeto funciona, quais recursos sao
criados antes da aplicacao e como testar a pipeline no GitHub Actions.

## Visao Geral

O deploy tem duas partes:

1. **Bootstrap local**: cria os recursos que o GitHub Actions precisa para rodar.
2. **Pipeline da aplicacao**: builda a Lambda e aplica o Terraform da aplicacao.

O bootstrap e executado uma vez pela sua maquina. A pipeline da aplicacao roda no
GitHub Actions depois que um pull request `feature/*` e mergeado em `main`.

```text
Sua maquina
  -> terraform-bootstrap
  -> S3 bucket de state
  -> DynamoDB lock table
  -> GitHub OIDC provider
  -> IAM role para GitHub Actions

GitHub Actions
  -> npm ci
  -> npm run typecheck
  -> npm run build
  -> terraform init com backend S3
  -> terraform validate
  -> terraform plan
  -> terraform apply
  -> API Gateway + Lambda + SNS + SQS + CloudWatch
```

## Por Que Existe Um Bootstrap Separado

O workflow precisa de duas coisas antes de conseguir aplicar Terraform:

- `AWS_ROLE_TO_ASSUME`: role que o GitHub Actions assume na AWS.
- `TF_STATE_BUCKET`: bucket S3 onde o Terraform guarda o state remoto.

Esses recursos precisam existir antes do primeiro `terraform init` do CI. Por
isso eles ficam em `terraform-bootstrap/`, separado do Terraform da aplicacao.

## 1. Rodar O Bootstrap Local

Configure suas credenciais AWS localmente:

```bash
aws configure
```

Entre na pasta do bootstrap:

```bash
cd terraform-bootstrap
```

Crie o arquivo local de variaveis:

```bash
cp terraform.tfvars.example terraform.tfvars
```

No PowerShell:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars`:

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

Ao final, copie os outputs:

```bash
terraform output -raw github_actions_role_arn
terraform output -raw state_bucket_name
terraform output -raw lock_table_name
terraform output -raw state_key
```

## 2. Configurar GitHub Secrets E Variables

No GitHub:

```text
Repository -> Settings -> Secrets and variables -> Actions
```

Crie este **Repository secret**:

```text
AWS_ROLE_TO_ASSUME = arn:aws:iam::761018861028:role/payment-ms-dev-github-actions-deploy
```

Crie estas **Repository variables**:

```text
TF_STATE_BUCKET = payment-ms-dev-761018861028-us-east-1-tfstate
TF_LOCK_TABLE   = payment-ms-dev-terraform-locks
TF_STATE_KEY    = payment-ms/dev/terraform.tfstate
AWS_REGION      = us-east-1
```

As variaveis opcionais `TF_APP_NAME`, `TF_ENVIRONMENT`, `TF_COST_CENTER` e
`TF_LOG_RETENTION_DAYS` nao precisam ser criadas agora porque o Terraform ja tem
valores default.

## 3. Como A Pipeline E Disparada

O workflow esta em:

```text
.github/workflows/deploy-lambda.yml
```

Ele roda somente quando:

- um pull request aponta para `main`;
- o PR foi mergeado;
- a branch de origem comeca com `feature/`.

Trecho relevante:

```yaml
on:
  pull_request:
    branches:
      - main
    types:
      - closed

if: ${{ github.event.pull_request.merged == true && startsWith(github.event.pull_request.head.ref, 'feature/') }}
```

## 4. Testar A Pipeline

Depois de configurar os secrets e variables, crie uma branch de teste:

```bash
git checkout -b feature/test-pipeline
```

Faca uma alteracao pequena e commit:

```bash
git add .
git commit -m "test deployment pipeline"
git push -u origin feature/test-pipeline
```

No GitHub:

1. Abra um PR de `feature/test-pipeline` para `main`.
2. Faca merge do PR.
3. Abra a aba `Actions`.
4. A workflow `Deploy Lambda` deve iniciar.

## 5. O Que A Pipeline Faz

1. Faz checkout do commit mergeado.
2. Instala dependencias em `api/` com `npm ci`.
3. Executa `npm run typecheck`.
4. Executa `npm run build`.
5. Configura credenciais AWS usando OIDC.
6. Roda `terraform fmt -check`.
7. Roda `terraform init` usando o backend S3.
8. Roda `terraform validate`.
9. Roda `terraform plan`.
10. Publica o ZIP da Lambda como artifact.
11. Executa `terraform apply`.

## 6. Resultado Esperado

O Terraform da aplicacao cria:

- API Gateway HTTP API.
- Lambda Producer em Node.js 22.
- SNS topic.
- SQS queue.
- SQS dead letter queue.
- CloudWatch log groups.
- IAM role e policies da Lambda.

O output principal e:

```bash
terraform output -raw api_url_post
```

O endpoint esperado usa:

```text
POST /payment
```

## 7. Troubleshooting

### O workflow nao apareceu

Confirme que o arquivo `.github/workflows/deploy-lambda.yml` ja esta na branch
`main`. Se ele foi criado em uma branch, ele passa a existir em `main` apenas
depois do primeiro merge.

### O workflow apareceu, mas nao rodou

Confirme que a branch de origem comeca com:

```text
feature/
```

Branches como `fix/test` ou `dev` nao disparam o deploy.

### Erro em `AWS_ROLE_TO_ASSUME`

Confirme que o secret foi criado em **Repository secrets**, nao em Environment
secrets.

### Erro em `terraform init`

Confirme as variables:

```text
TF_STATE_BUCKET
TF_STATE_KEY
TF_LOCK_TABLE
AWS_REGION
```

Tambem confirme se o bucket e a tabela foram criados pelo bootstrap.

### Erro de permissao AWS

Confirme se o bootstrap foi aplicado com o `github_owner` e `github_repository`
corretos. A trust policy da role restringe qual repositorio pode assumir a role.

## 8. Destruir Recursos

Para destruir a aplicacao:

```bash
cd terraform
terraform init \
  -backend-config="bucket=<TF_STATE_BUCKET>" \
  -backend-config="key=<TF_STATE_KEY>" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=<TF_LOCK_TABLE>" \
  -backend-config="encrypt=true"

terraform destroy
```

Destrua o bootstrap apenas depois que a aplicacao ja tiver sido destruida:

```bash
cd terraform-bootstrap
terraform destroy
```
