# -----------------------------------------------------------------------------
# CloudFront Distribution
# Provides free trusted HTTPS on a *.cloudfront.net domain.
# No custom domain, no ACM certificate request, no DNS validation required.
# CloudFront terminates HTTPS from the browser and forwards plain HTTP
# to the ALB on port 80 — ECS tasks receive unencrypted traffic internally.
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  comment             = "${var.project_name} ECS Fargate distribution"
  default_root_object = ""

  # Origin — the ALB DNS name receives HTTP from CloudFront on port 80
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "${var.project_name}-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default cache behaviour — pass all requests through to the ALB unchanged
  default_cache_behavior {
    target_origin_id       = "${var.project_name}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    # Allow all HTTP methods so the app can handle POST, PUT, DELETE etc.
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]

    # Disable caching — forward everything to ECS/Nginx in real time
    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    # TTL = 0 means no caching — every request hits the origin
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    compress    = true
  }

  # No geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use CloudFront's default managed certificate.
  # Free, fully trusted, works on *.cloudfront.net — no configuration needed.
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # ALB listener must exist before CloudFront can use it as an origin
  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "${var.project_name}-cloudfront"
  }
}