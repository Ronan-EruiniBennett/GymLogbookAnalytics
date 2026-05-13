// This file contains the configuration for the S3 buckets used in the GymLog application, including the static web bucket, data bucket, and query bucket. It also includes a public access block to ensure that the data bucket is not publicly accessible.

//////////////////////////////////
// Data bucket configuration
//////////////////////////////////

resource "aws_s3_bucket_public_access_block" "blockpublicdata" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "data_bucket_ownership" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket_encryption" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

//////////////////////////////////
// Query bucket configuration
//////////////////////////////////

resource "aws_s3_bucket_public_access_block" "blockpublicquery" {
  bucket = aws_s3_bucket.query_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "query_bucket_ownership" {
  bucket = aws_s3_bucket.query_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "query_bucket_encryption" {
  bucket = aws_s3_bucket.query_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

//////////////////////////////////
// Static web bucket configuration
//////////////////////////////////

// Block Public Access
resource "aws_s3_bucket_public_access_block" "blockpublicstatic" {
  bucket = aws_s3_bucket.static_web_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Define IAM policy document for CloudFront to access the static web bucket
data "aws_iam_policy_document" "CloudfrontReadOnlyPolicy_static_web_bucket" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.static_web_bucket.arn,
    "${aws_s3_bucket.static_web_bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.static_web_distribution.arn]
    }
  }
}

// Bucket policy to allow CloudFront OAC
resource "aws_s3_bucket_policy" "static_web_bucket_policy" {
  bucket = aws_s3_bucket.static_web_bucket.id
  policy = data.aws_iam_policy_document.CloudfrontReadOnlyPolicy_static_web_bucket.json
}

// Enable versioning on the static web bucket 
resource "aws_s3_bucket_versioning" "static_web_bucket_versioning" {
  bucket = aws_s3_bucket.static_web_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

// Enable server-side encryption on the static web bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "static_web_bucket_encryption" {
  bucket = aws_s3_bucket.static_web_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// Enable ownership controls on the static web bucket to enforce bucket owner ownership
resource "aws_s3_bucket_ownership_controls" "static_web_bucket_ownership" {
  bucket = aws_s3_bucket.static_web_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

//////////////////////////////////
// Log Bucket
//////////////////////////////////

resource "aws_s3_bucket_public_access_block" "block_public_logs" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "log_bucket_ownership" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

resource "aws_s3_bucket_lifecycle_configuration" "log_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.bucket

  rule {
    id = "log_lifecycle"

    expiration {
      days = 30
    }
    status = "Enabled"

    filter {}
  }
}

// Log delivery Policy for s3 permissions
data "aws_iam_policy_document" "cloudfront_delivery_policy" {
  statement {
    sid    = "AllowCloudfrontPushToS3Logs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.log_bucket.arn}/*"]
  }
}

// s3 bucket policy for logs
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.bucket
  policy = data.aws_iam_policy_document.cloudfront_delivery_policy.json
}