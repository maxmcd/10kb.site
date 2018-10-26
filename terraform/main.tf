provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "max"
  version                 = "~> 1.41"
}

resource "aws_acm_certificate" "10kb_site" {
  domain_name               = "10kb.site"
  subject_alternative_names = ["*.10kb.site"]
  validation_method         = "DNS"
}

output "record_name" {
  value = "${aws_acm_certificate.10kb_site.domain_validation_options.0.resource_record_name}"
}

output "record_value" {
  value = "${aws_acm_certificate.10kb_site.domain_validation_options.0.resource_record_value}"
}

resource "aws_s3_bucket" "10kb_site" {
  bucket = "10kb.site"
  acl    = "private"
}

locals {
  s3_origin_id = "10kb_site"
}

resource "aws_cloudfront_origin_access_identity" "10kb_site" {
  comment = "Some comment"
}

resource "aws_cloudfront_distribution" "10kb_site" {
  origin {
    domain_name = "${aws_s3_bucket.10kb_site.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.10kb_site.cloudfront_access_identity_path}"
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  # comment             = "Some comment"
  default_root_object = "index.html"

  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }

  aliases = ["10kb.site"]
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.10kb_site.arn}"
    ssl_support_method = "sni-only"
  }
}
