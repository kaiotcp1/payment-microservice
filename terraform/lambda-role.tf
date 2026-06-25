data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_producer" {
  name               = "${var.app_name}-${var.environment}-lambda-producer-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Role assumed by the Producer Lambda to publish to SNS and write logs"
}

data "aws_iam_policy_document" "lambda_producer_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.payment.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.lambda_producer.arn}:*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_producer" {
  name   = "${var.app_name}-${var.environment}-lambda-producer-policy"
  role   = aws_iam_role.lambda_producer.id
  policy = data.aws_iam_policy_document.lambda_producer_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_producer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
