resource "aws_sqs_queue" "payment_dlq" {
  name                      = "${var.app_name}-${var.environment}-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = {
    Name        = "${var.app_name}-${var.environment}-dlq"
    Description = "Dead Letter Queue for failed payment messages"
  }
}

resource "aws_sqs_queue" "payment" {
  name                       = "${var.app_name}-${var.environment}-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600
  delay_seconds              = 0
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.payment_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-queue"
    Description = "Main queue for payment processing"
  }
}

resource "aws_sqs_queue_policy" "payment" {
  queue_url = aws_sqs_queue.payment.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [aws_sqs_queue.payment.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.payment.arn]
    }
  }

  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:PurgeQueue",
    ]

    resources = [aws_sqs_queue.payment.arn]
  }
}
