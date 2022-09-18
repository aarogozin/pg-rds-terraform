# Fetch AZs in the current region
data "aws_availability_zones" "available" {}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = ["${aws_vpc.project_vpc.id}"]
  }
  depends_on = [
    aws_subnet.private
  ]
  tags = {
    Tier        = "Private"
    Environment = "${var.env}"
  }
}

# VPC for each environment.
resource "aws_vpc" "project_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "Terraform VPC"
    Environment = "${var.env}"
  }
}

# Create private subnets for RDS in two AZ, you need two AZ to create rds_subnet.
resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.project_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.project_vpc.id
  tags = {
    Name          = "private subnet"
    ResourceGroup = "Terraform"
    Environment   = "${var.env}"
    Tier          = "Private"
  }
}

# Create public subnets in two AZ for ECS and pg-admin.
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.project_vpc.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.project_vpc.id
  map_public_ip_on_launch = true
  tags = {
    Name          = "public subnet"
    ResourceGroup = "Terraform"
    Tier          = "Public"
    Environment   = "${var.env}"
  }
}

# IGW for the public subnet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name          = "internet gateway"
    ResourceGroup = "Terraform"
    Environment   = "${var.env}"

  }
}

# Route the public subnet traffic through the IGW.
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.project_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "pg-subnet-group-${var.env}"
  subnet_ids = tolist(data.aws_subnets.private.ids)


  tags = {
    Name          = "Postgres DB subnet"
    ResourceGroup = "Terraform"
    Environment   = "${var.env}"
  }

}

# Target group for pg-admin with lb managed stickiness.
resource "aws_alb_target_group" "pg-admin" {
  name     = "pg-admin-tg-${var.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project_vpc.id
  stickiness {
    type = "lb_cookie"
  }
}

# Create LB for pg-admin ecs target group.
resource "aws_alb" "pg-admin-alb" {
  name            = "pg-admin-${var.env}-alb"
  security_groups = [aws_security_group.alb_sg.id]
  subnets         = tolist(data.aws_subnets.public.ids)

  tags = {
    Name          = "pg-admin-${var.env} ALB"
    ResourceGroup = "Terraform"
    Environment   = "${var.env}"
  }
}

# Redirection rule for pg-admin. 
# So you dont have to specify https// before url.
resource "aws_alb_listener" "alb-redirect" {
  load_balancer_arn = aws_alb.pg-admin-alb.arn
  protocol          = "HTTP"
  port              = "80"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listener for HTTPS with certificate for secure connection.
resource "aws_alb_listener" "pg-admin" {
  load_balancer_arn = aws_alb.pg-admin-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.pg-admin-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.pg-admin.arn
  }
}
# certificate attachment for pg-admin listener in alb.
resource "aws_alb_listener_certificate" "pg-admin-cert" {
  listener_arn    = aws_alb_listener.pg-admin.arn
  certificate_arn = aws_acm_certificate.pg-admin-cert.arn
}


# Alb rule which forward request to ALB.
resource "aws_alb_listener_rule" "pg-admin" {
  listener_arn = aws_alb_listener.pg-admin.arn
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.pg-admin.arn
  }
  condition {
    host_header {
      values = ["${aws_route53_record.admin-project-de.fqdn}"]
    }
  }
}
