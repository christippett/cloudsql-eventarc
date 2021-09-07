provider "google" {
  project = var.config.project
  region  = var.config.region
  zone    = var.config.zone
}

provider "google-beta" {
  project = var.config.project
  region  = var.config.region
  zone    = var.config.zone
}
