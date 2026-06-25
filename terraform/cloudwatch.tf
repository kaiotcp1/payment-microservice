resource "aws_cloudwatch_log_group" "lambda_producer" {
  name              = "/aws/lambda/${var.app_name}-${var.environment}-producer"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.app_name}-${var.environment}-lambda-logs"
    Description = "Lambda Producer logs"
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.payment.name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.app_name}-${var.environment}-apigw-logs"
    Description = "API Gateway access logs"
  }
}
