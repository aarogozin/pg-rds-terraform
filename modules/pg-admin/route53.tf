# You should have rights to manage this zone, for testing purpose I setup my DNS zone manually via console and use my external DNS domain name rogozin.de 
# Without that certificate validation will fail and all deployment won't work.
# After I add DNS zone manually i just disable this block and "depends_on" atribute in "data "aws_route53_zone" "project" data block."

# DNS zone in route53, if you set up this manually please comment this resourse block and specify zone name in variable for data "aws_route53_zone" "project".
resource "aws_route53_zone" "project_dns_name" {
  name = var.route53_zone
}

# Fetch zone id.
data "aws_route53_zone" "project" {
  name = "${var.route53_zone}."
  depends_on = [
    aws_route53_zone.project_dns_name
  ]
}

# dns record for pg-admin frontend.
resource "aws_route53_record" "admin-project-de" {
  name    = var.hostname
  type    = "A"
  zone_id = data.aws_route53_zone.project.id
  alias {
    evaluate_target_health = false
    name                   = aws_alb.pg-admin-alb.dns_name
    zone_id                = aws_alb.pg-admin-alb.zone_id
  }
}

# Create Amazon managed certificate for pg-admin frontend.
resource "aws_acm_certificate" "pg-admin-cert" {
  domain_name               = "${var.hostname}.${var.route53_zone}"
  subject_alternative_names = ["*.${var.hostname}.${var.route53_zone}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name          = "${var.hostname}.${var.route53_zone}"
    ResourceGroup = "Terraform"
    Environment   = "${var.env}"
    Service       = "pg-admin"
  }
}

# Record for DNS validation challenge.
resource "aws_route53_record" "pg-admin-cert-validation" {
  name    = tolist(aws_acm_certificate.pg-admin-cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.pg-admin-cert.domain_validation_options)[0].resource_record_type
  zone_id = data.aws_route53_zone.project.id
  records = [tolist(aws_acm_certificate.pg-admin-cert.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

# Certificate validation.
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.pg-admin-cert.arn
  validation_record_fqdns = [
    "${aws_route53_record.pg-admin-cert-validation.fqdn}",
  ]
}
