# Terraform Bootstrap

This stack creates the AWS resources that the GitHub Actions deployment workflow
needs before it can deploy the application stack:

- S3 bucket for Terraform remote state.
- DynamoDB table for Terraform state locking.
- GitHub Actions OIDC provider, unless you pass an existing provider ARN.
- IAM role that GitHub Actions assumes during deploy.

## Why this is separate

The application workflow needs `AWS_ROLE_TO_ASSUME` and `TF_STATE_BUCKET` before it
can run `terraform init` and `terraform apply`. Because of that, the role and the
state bucket cannot be created by the first application deploy in GitHub Actions.
Run this bootstrap stack once from your machine with AWS credentials.

## 1. Configure AWS locally

Use an AWS identity allowed to create IAM roles, S3 buckets, and DynamoDB tables.

```bash
aws configure
```

## 2. Create your local tfvars

```bash
cd terraform-bootstrap
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
github_owner      = "your-github-user-or-org"
github_repository = "payment-microservice"
```

Keep `terraform.tfvars` local. It is ignored by git.

If your AWS account already has a GitHub Actions OIDC provider, set its ARN
instead of creating a duplicate:

```hcl
github_oidc_provider_arn = "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
```

## 3. Apply bootstrap

```bash
terraform init
terraform plan
terraform apply
```

## 4. Configure GitHub

After apply, read the outputs:

```bash
terraform output github_actions_role_arn
terraform output state_bucket_name
terraform output lock_table_name
terraform output state_key
```

In GitHub, open your repository settings:

`Settings -> Secrets and variables -> Actions`

Create this repository secret:

```text
AWS_ROLE_TO_ASSUME = <github_actions_role_arn output>
```

Create these repository variables:

```text
TF_STATE_BUCKET = <state_bucket_name output>
TF_LOCK_TABLE   = <lock_table_name output>
TF_STATE_KEY    = <state_key output>
AWS_REGION      = us-east-1
```

`TF_STATE_KEY`, `TF_LOCK_TABLE`, and `AWS_REGION` are optional for the workflow, but
setting them makes the deployment explicit.

## 5. Run the application deployment

The application workflow runs when a `feature/*` pull request is merged into
`main`.

## Security note

By default, the deploy role gets `AdministratorAccess`. This is acceptable for a
small learning/dev project because the trust policy restricts role assumption to
your GitHub repository.

For production, create a narrower managed policy, set:

```hcl
attach_administrator_policy = false
additional_policy_arns      = ["arn:aws:iam::<account-id>:policy/<policy-name>"]
```

Then re-apply the bootstrap stack.
