output "bucket_name" {
  value = aws_s3_bucket.matches.bucket
}

output "queue_url" {
  value = aws_sqs_queue.main.url
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "processor_arn" {
  value = aws_lambda_function.processor.arn
}
