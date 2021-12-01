resource "aws_s3_bucket" "backup_bucket" {
  bucket = var.s3_bucket
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3_encryption_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    id      = "glacier-move"
    enabled = true
    prefix = "/scheduled"

    transition {
      days          = var.s3_days_until_glacier
      storage_class = "GLACIER"
    }
    expiration {
      days = var.s3_days_until_expiry
    }

    tags  = local.common_tags
  }
  tags  = local.common_tags
}

resource "aws_kms_key" "s3_encryption_key" {
  description             = "key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  tags                    = local.common_tags
}
