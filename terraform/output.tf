output "db" {
  value     = local.db
  sensitive = true
}

output "database_url" {
  value     = "postgres://${local.db.user}:${local.db.pass}@/${local.db.name}?socket=${local.db.socket}&search_path=meta,public"
  sensitive = true
}

output "cloudsql_connection_name" {
  value = local.db.cloudsql_connection
}
