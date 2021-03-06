
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "google_compute_default_service_account" "default" {
}

# PubSub -----------------------------------------------------------------------

resource "google_pubsub_topic" "cloudsql_events" {
  name = "${var.name}-events"

  labels = {
    channel = "pg2bq"
  }
}

# Cloud SQL --------------------------------------------------------------------

module "cloudsql" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "6.0.0"

  deletion_protection = false

  project_id    = var.config.project
  region        = var.config.region
  zone          = var.config.zone
  name          = var.name
  db_name       = var.db_name
  user_name     = var.db_user
  user_password = var.db_pass

  random_instance_name = true
  database_flags       = [for k, v in var.database_flags : { name = k, value = v }]
  database_version     = "POSTGRES_13"
  availability_type    = "REGIONAL"
  tier                 = "db-f1-micro"

  insights_config = {
    query_string_length     = 800
    record_application_tags = false
    record_client_address   = false
  }

  ip_configuration = {
    authorized_networks = [{
      name  = "home"
      value = "${chomp(data.http.myip.body)}/32"
    }]
    ipv4_enabled    = true
    private_network = null
    require_ssl     = null
  }
}

locals {
  db = {
    # socket     = "/cloudsql/${module.cloudsql.instance_connection_name}/.s.PGSQL.5432"
    socket              = "/cloudsql/${module.cloudsql.instance_connection_name}"
    public_ip           = module.cloudsql.instance_first_ip_address
    private_ip          = module.cloudsql.private_ip_address
    cloudsql_connection = module.cloudsql.instance_connection_name
    name                = var.db_name
    user                = var.db_user
    pass                = coalesce(var.db_pass, module.cloudsql.generated_user_password)
  }
}

resource "google_secret_manager_secret" "cloudsql_credentials" {
  secret_id = "${var.name}-cloudsql"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "cloudsql_credentials" {
  secret = google_secret_manager_secret.cloudsql_credentials.id

  secret_data = jsonencode(local.db)
}

resource "google_secret_manager_secret_iam_member" "cloudsql_credentials" {
  provider = google-beta

  secret_id = google_secret_manager_secret.cloudsql_credentials.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}


# BigQuery ---------------------------------------------------------------------

// bigqueryconnection.googleapis.com

resource "google_bigquery_connection" "connection" {
  provider = google-beta
  location = var.config.region
  cloud_sql {
    instance_id = module.cloudsql.instance_connection_name
    database    = local.db.name
    type        = "POSTGRES"
    credential {
      username = local.db.user
      password = local.db.pass
    }
  }
}

resource "google_bigquery_dataset" "events" {
  dataset_id = replace(var.name, "-", "_")
  location   = var.config.region

  lifecycle {
    ignore_changes = [access]
  }
}
resource "google_bigquery_table" "events" {
  dataset_id = google_bigquery_dataset.events.dataset_id
  table_id   = "events"
  clustering = ["table_schema", "table_name"]

  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "created"
  }

  schema = <<EOF
  [
    {
      "name": "id",
      "type": "INTEGER",
      "mode": "REQUIRED"
    },
    {
      "name": "op",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "table_schema",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "table_name",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "data",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "status",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "created",
      "type": "TIMESTAMP",
      "mode": "REQUIRED"
    },
    {
      "name": "updated",
      "type": "TIMESTAMP",
      "mode": "REQUIRED"
    }
  ]
  EOF
}

# Eventarc ---------------------------------------------------------------------

locals {
  eventarc_criteria = {
    "type"         = "google.cloud.audit.log.v1.written"
    "serviceName"  = "cloudsql.googleapis.com"
    "methodName"   = "cloudsql.instances.query"
    "resourceName" = "instances/${module.cloudsql.instance_name}"
  }
}

resource "google_eventarc_trigger" "trigger" {
  name            = "${var.name}-trigger"
  location        = var.config.region
  service_account = data.google_compute_default_service_account.default.email

  dynamic "matching_criteria" {
    for_each = local.eventarc_criteria
    iterator = criteria
    content {
      attribute = criteria.key
      value     = criteria.value
    }
  }

  destination {
    cloud_run_service {
      service = google_cloud_run_service.handler.name
      region  = google_cloud_run_service.handler.location
    }
  }

  depends_on = [module.cloudsql, google_cloud_run_service.handler]
}

resource "google_cloud_run_service" "handler" {
  provider = google-beta

  name     = "${var.name}-handler"
  location = var.config.region

  autogenerate_revision_name = true

  metadata {
    namespace = var.config.project
    annotations = {
      "run.googleapis.com/cloudsql-instances"    = module.cloudsql.instance_connection_name
      "run.googleapis.com/client-name"           = "terraform"
      "run.googleapis.com/launch-stage"          = "BETA"
      "run.googleapis.com/ingress"               = "all"
      "run.googleapis.com/execution-environment" = "gen1"
      "autoscaling.knative.dev/maxScale"         = "3"
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  template {
    spec {
      containers {
        image = "gcr.io/${var.config.project}/cloudsql-eventarc:latest"
        volume_mounts {
          name       = "secret-d0400520-c354-4c7b-ae32-cc5aa266f7a3"
          mount_path = "/secrets"
        }
      }
      volumes {
        name = "secret-d0400520-c354-4c7b-ae32-cc5aa266f7a3"
        secret {
          secret_name = google_secret_manager_secret.cloudsql_credentials.secret_id
          items {
            key  = "latest"
            path = google_secret_manager_secret.cloudsql_credentials.secret_id
          }
        }
      }
      container_concurrency = 20
      service_account_name  = data.google_compute_default_service_account.default.email
    }
  }
}
