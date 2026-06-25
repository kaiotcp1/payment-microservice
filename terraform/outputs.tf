output "api_endpoint" {
  description = "API Gateway base URL"
  value       = aws_apigatewayv2_api.payment.api_endpoint
}

output "api_url_post" {
  description = "Full URL for POST /payment"
  value       = "${aws_apigatewayv2_api.payment.api_endpoint}/payment"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.producer.function_name
}

output "lambda_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.producer.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.payment.arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.payment.name
}

output "sqs_queue_url" {
  description = "Main SQS queue URL"
  value       = aws_sqs_queue.payment.url
}

output "sqs_queue_arn" {
  description = "Main SQS queue ARN"
  value       = aws_sqs_queue.payment.arn
}

output "sqs_dlq_url" {
  description = "Dead Letter Queue URL"
  value       = aws_sqs_queue.payment_dlq.url
}

output "sqs_dlq_arn" {
  description = "Dead Letter Queue ARN"
  value       = aws_sqs_queue.payment_dlq.arn
}

output "cloudwatch_log_group_lambda" {
  description = "Lambda log group name"
  value       = aws_cloudwatch_log_group.lambda_producer.name
}

output "cloudwatch_log_group_apigw" {
  description = "API Gateway log group name"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "aws_region" {
  description = "AWS region in use"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
