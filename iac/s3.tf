resource "aws_s3_bucket" "buckets" {
  bucket = "my-tf-test-bucket"
  force_destroy = true
       
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "buckets" {
    bucket = aws_s3_bucket.buckets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "buckets" {
  bucket = aws_s3_bucket.buckets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "buckets" {
  bucket                  = aws_s3_bucket.buckets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "buckets" {
  bucket = aws_s3_bucket.buckets.id

  rule {
    id     = "expire-uploads"
    status = "Enabled"

    filter { prefix = "uploads/" }

    expiration {
      days = var.uploads_expiration_days
    }
  }

  rule {
    id     = "expire-processed"
    status = "Enabled"

    filter { prefix = "processed/" }

    expiration {
      days = var.processed_expiration_days
    }
  }
}

resource "aws_s3_bucket_notification" "uploads_to_sqs" {
  bucket = aws_s3_bucket.buckets.id

  queue {
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }

  depends_on = [aws_sqs_queue_policy.main]
}
