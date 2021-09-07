variable "config" {
  type = object({
    project = string
    region  = string
    zone    = string
  })
}

variable "ip_whitelist" {
  type = map(string)
}

variable "name" {
  type    = string
  default = "pg2bq"
}

variable "db_name" {
  type    = string
  default = "scratch"
}

variable "db_user" {
  type    = string
  default = "sqladmin"
}

variable "db_pass" {
  type    = string
  default = ""
}

variable "database_flags" {
  type = map(string)
  default = {
    "cloudsql.enable_pgaudit" = "on"
    "pgaudit.log"             = "write"
    "pgaudit.log_catalog"     = "off"
    "pgaudit.log_parameter"   = "on"
  }
}
