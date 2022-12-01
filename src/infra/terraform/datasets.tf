resource "google_bigquery_dataset" "dataset" {
  dataset_id          = var.DATASET_ID
  friendly_name       = "Media analyzer dataset"
  description         = "Media analyzer pipeline results"
  location            = "EU"
  

  depends_on = [google_project_service.bigquery]
}

resource "google_service_account" "bqowner" {
  account_id = "bqowner"
}
