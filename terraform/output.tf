output "db" {
  value     = local.db
  sensitive = true
}

output "database_url" {
  value     = "postgres://${local.db.user}:${local.db.pass}@/${local.db.name}?socket=${local.db.host}&search_path=meta,public"
  sensitive = true
}

output "cloudsql_connection_name" {
  value = local.cloudsql_connection_name
}
