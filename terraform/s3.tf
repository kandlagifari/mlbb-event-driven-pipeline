resource "aws_s3_bucket" "matches" {
  bucket        = "${local.project}-matches"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "matches" {
  bucket                  = aws_s3_bucket.matches.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
