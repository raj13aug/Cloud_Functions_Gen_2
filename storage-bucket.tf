resource "google_storage_bucket" "Cloud_function_bucket" {
  name                        = "cloud-function-${var.project_id}"
  location                    = var.region
  project                     = var.project_id
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "input_bucket" {
  name                        = "input-${var.project_id}"
  location                    = var.region
  project                     = var.project_id
  force_destroy               = true
  uniform_bucket_level_access = true
}