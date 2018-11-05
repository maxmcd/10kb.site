provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "max"
  version                 = "~> 1.41"
}

resource "aws_acm_certificate" "10kb_site" {
  domain_name               = "10kb.site"
  subject_alternative_names = ["*.10kb.site"]
  validation_method         = "EMAIL"
}

resource "aws_s3_bucket" "10kb_site" {
  bucket = "10kb.site"
  acl    = "private"

  lifecycle_rule {
    id      = "uploads"
    enabled = true

    tags {
      "unprotected" = "true"
    }

    expiration {
      days = 1
    }
  }
}

locals {
  s3_origin_id = "10kb_site"
}

resource "aws_cloudfront_origin_access_identity" "10kb_site" {
  comment = "10kb_site bucket access"
}

data "aws_iam_policy_document" "10kb_site" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.10kb_site.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.10kb_site.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.10kb_site.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.10kb_site.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "10kb_site" {
  bucket = "${aws_s3_bucket.10kb_site.id}"
  policy = "${data.aws_iam_policy_document.10kb_site.json}"
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

  custom_error_response {
    error_code = "404"
    error_caching_min_ttl = 0
    response_page_path = "/not-found.txt"
    response_code = "404"
  }

  aliases = ["www.10kb.site"]
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

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
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
    ssl_support_method  = "sni-only"
  }
}

output "cloudfront-subdomain" {
  value = "Set CNAME for cloudfront record: ${aws_cloudfront_distribution.10kb_site.domain_name}"
}

output "cloudfront-distribution-id" {
  value = "${aws_cloudfront_distribution.10kb_site.id}"
}
