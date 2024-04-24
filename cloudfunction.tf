resource "google_project_service" "cf" {
  project            = var.project_id
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = true
}

resource "google_project_service" "cb" {
  project            = var.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = true
}

resource "google_project_service" "ev" {
  project            = var.project_id
  service            = "eventarc.googleapis.com"
  disable_on_destroy = true
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [google_project_service.cf, google_project_service.cb, google_project_service.ev]

  create_duration = "60s"
}

resource "google_service_account" "myaccount" {
  project      = var.project_id
  account_id   = "gen2-sa"
  display_name = "My Service Account"
}

resource "google_project_iam_member" "signed-url" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.myaccount.email}"
}

# Generates an archive of the source code compressed as a .zip file.
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/tmp/function.zip"
}

# Add source code zip to the Cloud Function's bucket (Cloud_function_bucket) 
resource "google_storage_bucket_object" "zip" {
  source       = data.archive_file.source.output_path
  content_type = "application/zip"
  name         = "src-${data.archive_file.source.output_md5}.zip"
  bucket       = google_storage_bucket.Cloud_function_bucket.name
  depends_on = [
    google_storage_bucket.Cloud_function_bucket,
    data.archive_file.source,
    time_sleep.wait_30_seconds
  ]
}

resource "google_cloudfunctions2_function" "function" {
  name        = "Cloud-function-trigger-using-terraform-gen-2"
  location    = var.region
  description = "Cloud function gen2 trigger using terraform "

  build_config {
    runtime     = "python39"
    entry_point = "helloGET"
    environment_variables = {
      BUILD_CONFIG_TEST = "build_test"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.Cloud_function_bucket.name
        object = google_storage_bucket_object.zip.name
      }
    }
  }

  service_config {
    max_instance_count = 3
    min_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      SERVICE_CONFIG_TEST = "config_test"
    }
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.myaccount.email
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.storage.object.v1.finalized"
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.myaccount.email
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.input_bucket.name
    }
  }
  depends_on = [
    google_storage_bucket.Cloud_function_bucket,
    google_storage_bucket_object.zip,
    time_sleep.wait_30_seconds
  ]
}


resource "google_cloud_run_service_iam_member" "member" {
  project  = var.project_id
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}