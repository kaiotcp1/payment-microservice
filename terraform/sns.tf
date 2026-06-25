resource "aws_sns_topic" "payment" {
  name              = "${var.app_name}-${var.environment}-topic"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "${var.app_name}-${var.environment}-topic"
    Description = "SNS topic for payment events"
  }
}

resource "aws_sns_topic_subscription" "payment_sqs" {
  topic_arn            = aws_sns_topic.payment.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.payment.arn
  raw_message_delivery = true

  depends_on = [
    aws_sns_topic.payment,
    aws_sqs_queue.payment,
    aws_sqs_queue_policy.payment,
  ]
}
