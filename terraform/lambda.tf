locals {
  lambda_runtime = "python3.12"
  lambda_handler = "handler.handler"
  lambda_timeout = 10
}

resource "aws_cloudwatch_log_group" "validator" {
  name              = "/aws/lambda/${local.project}-validator"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "processor" {
  name              = "/aws/lambda/${local.project}-processor"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_lambda_function" "validator" {
  function_name = "${local.project}-validator"
  role          = aws_iam_role.ingestor.arn
  runtime       = local.lambda_runtime
  handler       = local.lambda_handler
  filename      = "../build/validator.zip"
  timeout       = local.lambda_timeout
  tags          = local.tags
  depends_on    = [aws_cloudwatch_log_group.validator]

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.main.url
      BUCKET    = aws_s3_bucket.matches.bucket
    }
  }
}

# prefix filter prevents rejected/ from re-triggering the validator
resource "aws_s3_bucket_notification" "matches" {
  bucket = aws_s3_bucket.matches.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.validator.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "matches/"
  }
  depends_on = [aws_lambda_permission.s3_invoke_validator]
}

resource "aws_lambda_function" "processor" {
  function_name = "${local.project}-processor"
  role          = aws_iam_role.processor.arn
  runtime       = local.lambda_runtime
  handler       = local.lambda_handler
  filename      = "../build/processor.zip"
  timeout       = local.lambda_timeout
  memory_size   = 256
  tags          = local.tags
  depends_on    = [aws_cloudwatch_log_group.processor]

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.leaderboard.name
      TOPIC_ARN  = aws_sns_topic.alerts.arn
      SSM_PREFIX = local.ssm_prefix
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_processor" {
  event_source_arn        = aws_sqs_queue.main.arn
  function_name           = aws_lambda_function.processor.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_permission" "s3_invoke_validator" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validator.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.matches.arn
}

resource "aws_security_group" "processor_lambda" {
  name   = "${local.project}-processor-lambda-sg"
  vpc_id = data.aws_vpc.default.id
  tags   = local.tags
}
