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

resource "aws_cloudfront_distribution" "static_web_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_web_bucket.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static_web_oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for static web hosting"
  default_root_object = "Index.html"
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