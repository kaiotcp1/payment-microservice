resource "aws_apigatewayv2_api" "payment" {
  name          = "${var.app_name}-${var.environment}-api"
  protocol_type = "HTTP"
  description   = "Payments API - Event-Driven Architecture Demo"

  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["POST", "OPTIONS"]
    allow_headers  = ["Content-Type", "X-Idempotency-Key", "Authorization"]
    expose_headers = ["X-Idempotency-Key"]
    max_age        = 3600
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-api"
    Description = "HTTP API for payment requests"
  }
}

resource "aws_apigatewayv2_stage" "payment" {
  api_id      = aws_apigatewayv2_api.payment.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      path             = "$context.path"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
      protocol         = "$context.protocol"
      integrationError = "$context.integrationErrorMessage"
      errorMessage     = "$context.error.message"
    })
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-stage"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_integration" "payment" {
  api_id                 = aws_apigatewayv2_api.payment.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.producer.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}

resource "aws_apigatewayv2_route" "payment_post" {
  api_id    = aws_apigatewayv2_api.payment.id
  route_key = "POST /payment"
  target    = "integrations/${aws_apigatewayv2_integration.payment.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.payment.execution_arn}/*/*"
}
