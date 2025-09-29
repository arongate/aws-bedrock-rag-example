
resource "aws_s3_bucket" "example" {
  bucket        = "${local.project_name}-ds-bucket"
  force_destroy = true # we are in a test environment, so we want to be able to destroy the bucket even if it has objects in it

  tags = {
    Name = "${local.project_name}-ds-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_policy" "example" {
#   bucket = aws_s3_bucket.example.id
#   policy = data.aws_iam_policy_document.example.json
# }

resource "aws_kms_key" "kb_ds_encryption" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${local.project_name}-s3-bucket-key"
  }

}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.kb_ds_encryption.arn
    }
  }
}


resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["Access-Control-Allow-Origin"]
    # max_age_seconds = 3000
  }
}