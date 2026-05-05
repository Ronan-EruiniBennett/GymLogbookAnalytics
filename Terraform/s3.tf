// 3 S3 Buckets for GymLog Application. One for static files, one for data storage, and one for query results.
resource "aws_s3_bucket" "static_web_bucket" {
  bucket = var.static_bucket_name
}

// Index.html file upload with MD5 hash to detect changes and trigger updates in the static website hosting.
resource "aws_s3_object" "staticpage" {
  bucket       = aws_s3_bucket.static_web_bucket.id
  key          = "index.html"
  source       = var.index_path
  content_type = "text/html"

  etag = filemd5(var.index_path)
}

// Data bucket for storing user data and workout logs
resource "aws_s3_bucket" "data_bucket" {
  bucket = var.data_bucket_name
}

// Query bucket for storing results of Athena queries
resource "aws_s3_bucket" "query_bucket" {
  bucket = var.query_bucket_name
}