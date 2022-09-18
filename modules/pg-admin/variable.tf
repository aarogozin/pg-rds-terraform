variable "env" {
  description = "Environment name"
  default     = "stage"

}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "2"
}

variable "hostname" {
  description = "hostname for pg-admin"
  default     = "pg-admin"

}

variable "db_instance_class" {
  description = "Instance class for pg db"
  default     = "db.t3.micro"

}

variable "db_name" {
  description = "Database name"
  default     = "stage_pg_database"
}
variable "db_username" {
  description = "database master username"
  default     = "rogozin_db_admin"
}
variable "db_password" {
  description = "Database master user password"
  default     = "supersecretpassword"
}

variable "db_storage" {
  description = "Storage allocation for database"
  default     = "20"
}

variable "web_instance_type" {
  description = "Instance type for EC2"
  default     = "t2.micro"
}

variable "cidr_block" {
  description = "cidr block for vpc"
  default     = "10.0.0.0/16"
}


variable "pg_admin_email" {
  description = "pgadmin console admin default email"
  default     = "admin@rogozin.de"
}

variable "pg_admin_pass" {
  description = "pg_admin default pass"
  default     = "supersecretpassword"
}

variable "route53_zone" {
  description = "name of DNS zone in route53"
}

variable "project" {
  description = "project name, used for pg-admin db name"
}
