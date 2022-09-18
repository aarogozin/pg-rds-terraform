# Rds instance.
# TODO:
# specify backup strategy for each environments.
resource "aws_db_instance" "pg_rds" {
  identifier             = "${var.env}-postgres"
  allocated_storage      = var.db_storage
  engine                 = "postgres"
  engine_version         = "13.7"
  instance_class         = var.db_instance_class
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.id
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_master_pass.result
  skip_final_snapshot    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id, aws_security_group.ecs_sg.id]
  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

# Generate password for rds master user.
resource "random_password" "db_master_pass" {
  length           = 40
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
  keepers = {
    pass_version = 1
  }
}

# Create SSM parameter with master user password.
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.env}/database/password/master"
  description = "RDS master password for ${var.route53_zone}-${var.env}"
  type        = "SecureString"
  value       = random_password.db_master_pass.result

  tags = {
    environment = "${var.env}"
  }
}
