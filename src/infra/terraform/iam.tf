# Grant permissions to the App Engine default service account

resource "google_project_iam_member" "project-iam-appspot-dlp-admin" {
  role   = "roles/dlp.admin"
  member = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

resource "google_project_iam_member" "project-iam-appspot-dlp-service-agent" {
  role   = "roles/dlp.serviceAgent"
  member = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

# Grant permissions to the DLP service account

resource "google_project_iam_member" "project-iam-dlp-service-agent-viewer" {
  role   = "roles/viewer"
  member = "serviceAccount:service-${var.project_nb}@dlp-api.iam.gserviceaccount.com"
}

