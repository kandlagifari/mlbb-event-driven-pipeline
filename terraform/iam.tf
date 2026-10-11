data "aws_iam_policy_document" "ingestor" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.matches.arn}/matches/*"]
  }
  statement {
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.matches.arn}/rejected/*"]
  }
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.main.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

data "aws_iam_policy_document" "processor" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [aws_sqs_queue.main.arn]
  }
  statement {
    actions   = ["dynamodb:TransactWriteItems", "dynamodb:UpdateItem", "dynamodb:GetItem", "dynamodb:PutItem"]
    resources = [aws_dynamodb_table.leaderboard.arn]
  }
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
  }
  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter${local.ssm_prefix}/*"]
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:*:*:key/*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ingestor" {
  name               = "${local.project}-ingestor-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "ingestor" {
  role   = aws_iam_role.ingestor.id
  policy = data.aws_iam_policy_document.ingestor.json
}

resource "aws_iam_role" "processor" {
  name               = "${local.project}-processor-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "processor" {
  role   = aws_iam_role.processor.id
  policy = data.aws_iam_policy_document.processor.json
}
