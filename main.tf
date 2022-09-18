module "pg-admin-prod" {
  source       = "./modules/pg-admin"
  env          = "prod"
  cidr_block   = "10.0.0.0/16"
  db_name      = "prod_db"
  db_username  = "db_admin"
  route53_zone = "example.de"
  project      = "example.de"
  hostname     = "pg-admin"
}

module "pg-admin-stage" {
  source       = "./modules/pg-admin"
  env          = "stage"
  cidr_block   = "10.1.0.0/16"
  db_name      = "prod_db"
  db_username  = "db_admin"
  route53_zone = "example.de"
  project      = "stage-example.de"
  hostname     = "pg-admin-stage"
}
