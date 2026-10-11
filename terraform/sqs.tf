resource "aws_sqs_queue" "dlq" {
  name = "${local.project}-dlq"
  tags = local.tags
}

resource "aws_sqs_queue" "main" {
  name                       = "${local.project}-main-queue"
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 2
  })
  tags = local.tags
}
