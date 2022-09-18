output "db_password" {
  description = "rds master password"
  value       = "You can find database passoword as SSM parameter in AWS console ${aws_ssm_parameter.db_password.name}"
}

output "pg-admin-pass" {
  description = "pg admin password"
  value       = "You can find pg-admin passoword as SSM parameter in AWS console ${aws_ssm_parameter.pg_admin_pass.name}"
}

output "pg_admin_login" {
  description = "pg admin email for login"
  value       = var.pg_admin_email
}

output "pg-admin-url" {
  description = "URL for pg-admin"
  value       = "https://${aws_route53_record.admin-project-de.fqdn}"
}

output "project_rote53_zone" {
  value = aws_route53_zone.project_dns_name
}
