resource "google_storage_notification" "notification" {
  bucket         = "${var.project_id}-upload"
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.notification.id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_binding.binding]
}

// Enable notifications by giving the correct IAM permission to the unique service account.

data "google_storage_project_service_account" "gcs_account" {
  # service-613575239900@gs-project-accounts.iam.gserviceaccount.com'
}

resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = google_pubsub_topic.notification.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}