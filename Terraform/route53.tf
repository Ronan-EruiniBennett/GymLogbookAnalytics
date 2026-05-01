// Already created hosted zone
data "aws_route53_zone" "rebgymlog" {
  name         = "rebgymlog.info"
  private_zone = false
}

// Create a record for the subdomain tf.rebgymlog.info that points to rebgymlog.info
resource "aws_route53_record" "subdomain_record" {
  zone_id = data.aws_route53_zone.rebgymlog.zone_id
  name    = "tf.rebgymlog.info"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.static_web_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.static_web_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

// Create an ACM certificate for the subdomain tf.rebgymlog.info in us-east-1 region
resource "aws_acm_certificate" "subdomain" {
  provider          = aws.us-east-1
  domain_name       = "tf.rebgymlog.info"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

}

// Create a Route53 record for the ACM certificate validation
resource "aws_route53_record" "acm_validation" {
  for_each = { for dvo in aws_acm_certificate.subdomain.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
  allow_overwrite = true
  zone_id         = data.aws_route53_zone.rebgymlog.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.value]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "validation_process" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.subdomain.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]

}

