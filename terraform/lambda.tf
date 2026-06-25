data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../api/dist"
  output_path = "${path.module}/../dist/payment-producer.zip"
}

resource "aws_lambda_function" "producer" {
  function_name = "${var.app_name}-${var.environment}-producer"
  description   = "Producer Lambda: validates payment payloads and publishes to SNS"

  runtime          = "nodejs22.x"
  handler          = "main.handler"
  role             = aws_iam_role.lambda_producer.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  architectures = ["arm64"]
  memory_size   = 256
  timeout       = 10

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.lambda_producer.name
  }

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.payment.arn
      APP_NAME      = var.app_name
      LOG_LEVEL     = "info"
      NODE_ENV      = "production"
    }
  }

  tags = {
    Name         = "${var.app_name}-${var.environment}-producer"
    Runtime      = "nodejs22.x"
    Architecture = "arm64"
  }

  depends_on = [
    aws_iam_role_policy.lambda_producer,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda_producer,
  ]
}
