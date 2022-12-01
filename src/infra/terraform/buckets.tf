# upload bucket
resource "google_storage_bucket" "upload-bucket" {
  name     = "${var.project_id}-upload"
  location = "EU"
  force_destroy = true
}

# filtered bucket
resource "google_storage_bucket" "filtered-bucket" {
  name     = "${var.project_id}-filtered"
  location = "EU"
  force_destroy = true
}

# flagged-bucket
resource "google_storage_bucket" "flagged-bucket" {
  name     = "${var.project_id}-flagged"
  location = "EU"
  force_destroy = true
}

# staging-bucket
resource "google_storage_bucket" "staging-bucket" {
  name     = "${var.project_id}-staging"
  location = "EU"
  force_destroy = true
}


##################  DLP  ####################

# upload bucket
resource "google_storage_bucket" "quarantine-bucket" {
  name     = "${var.project_id}-dlp-quarantine"
  location = "EU"
  #force_destroy = true
}

# sensitive content bucket
resource "google_storage_bucket" "sensitive-bucket" {
  name     = "${var.project_id}-dlp-sensitive"
  location = "EU"
  #force_destroy = true
}

# nonsensitive content bucket
resource "google_storage_bucket" "nonsensitive-bucket" {
  name     = "${var.project_id}-dlp-nonsensitive"
  location = "EU"
  #force_destroy = true
}

# staging-bucket
resource "google_storage_bucket" "staging-dlp-bucket" {
  name     = "${var.project_id}-dlp-staging"
  location = "EU"
  #force_destroy = true
}