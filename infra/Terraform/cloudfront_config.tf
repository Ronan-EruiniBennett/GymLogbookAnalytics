locals {
  s3_origin_id = "s3-static-web-origin"
}

// OAC for CloudFront to access S3 bucket
resource "aws_cloudfront_origin_access_control" "static_web_oac" {
  name                              = "static-web-oac"
  description                       = "Origin Access Control for static web bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

// Creating the Cloudfront distribution
resource "aws_cloudfront_distribution" "static_web_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_web_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static_web_oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for static web hosting"
  default_root_object = "index.html"
  http_version        = "http2and3"


  aliases = ["${var.my_domain_name}"]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"


    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
    compress    = true
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["AU"]
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.validation_process.certificate_arn
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.3_2025"
  }
}

// Setting up logging for cloudwatch to deliver to s3
resource "aws_cloudwatch_log_delivery_source" "cloudwatch_logs" {
  provider = aws.us-east-1
  name     = "cloudfront_log_source"
  log_type = "ACCESS_LOGS"

  resource_arn = aws_cloudfront_distribution.static_web_distribution.arn
}

resource "aws_cloudwatch_log_delivery_destination" "cloudwatch_logs" {
  name     = "cloudfront_log_destination"
  provider = aws.us-east-1

  delivery_destination_configuration {
    destination_resource_arn = aws_s3_bucket.log_bucket.arn
  }

  delivery_destination_type = "S3"
  output_format             = "json"
}

resource "aws_cloudwatch_log_delivery" "cloudwatch_logs" {
  provider                 = aws.us-east-1
  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudwatch_logs.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudwatch_logs.arn

  record_fields = [
    "date",
    "time",
    "c-ip",
    "cs-method",
    "cs(Host)",
    "cs-uri-stem",
    "sc-status",
    "time-taken",
    "x-edge-location",
    "x-edge-result-type",
    "x-forwarded-for",
    "cs(User-Agent)",
    "cs(Referer)"
  ]
}
