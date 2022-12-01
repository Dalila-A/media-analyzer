# ======== GCStoPubsub ========
# gcloud functions deploy GCStoPubsub --runtime python39 --stage-bucket gs://dab-media-analyzer-dev-staging --trigger-topic upload_notification --entry-point entry_point --region europe-west1   --set-env-vars=PROJECT_ID=$PROJECT_ID,RESULT_BUCKET=$PROJECT_ID-filtered
locals {
  GCStoPubsub_zip          = "${path.module}/../../bin/GCStoPubsub.zip"
  insertIntoBigQuery_zip   = "${path.module}/../../bin/insertIntoBigQuery.zip"
  videoIntelligenceAPI_zip = "${path.module}/../../bin/videoIntelligenceAPI.zip"
  visionAPI_zip            = "${path.module}/../../bin/visionAPI.zip"
  create_DLP_job_zip       = "${path.module}/../../bin/create_DLP_job.zip"
  resolve_DLP_zip          = "${path.module}/../../bin/resolve_DLP.zip"
}

# "${local.function_name}.${data.archive_file.function_dist.output_md5}.zip",

data "archive_file" "GCStoPubsub_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../functions/GCStoPubsub"
  output_path = local.GCStoPubsub_zip
  excludes    = [".idea", "venv", ".vscode", "__pycache__", "examples"]
}

resource "google_storage_bucket_object" "GCStoPubsub_gcs" {
  name   = "${data.archive_file.GCStoPubsub_zip.output_md5}.zip"
  bucket = google_storage_bucket.staging-bucket.name
  source = local.GCStoPubsub_zip
}

resource "google_cloudfunctions_function" "GCStoPubsub" {
  name                  = "GCStoPubsub"
  runtime               = "python39"
  source_archive_bucket = google_storage_bucket.staging-bucket.name
  source_archive_object = google_storage_bucket_object.GCStoPubsub_gcs.name
  entry_point           = "entry_point"
  environment_variables = {
    PROJECT_ID    = var.project_id
    RESULT_BUCKET = "${var.project_id}-filtered"
  }

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.notification.id
  }



}

# ======== visionAPI ========
# gcloud functions deploy visionAPI --runtime python39 --stage-bucket gs://dab-media-analyzer-dev-staging --trigger-topic visionapiservice --entry-point entry_point --region europe-west1 --set-env-vars=PROJECT_ID=$PROJECT_ID,REJECTED_BUCKET=$PROJECT_ID-flagged

data "archive_file" "visionAPI_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../functions/visionAPI"
  output_path = local.visionAPI_zip
  excludes    = [".idea", "venv", ".vscode", "__pycache__", "examples"]
}

resource "google_storage_bucket_object" "visionAPI_gcs" {
  name   = "${data.archive_file.visionAPI_zip.output_md5}.zip"
  bucket = google_storage_bucket.staging-bucket.name
  source = local.visionAPI_zip
}

resource "google_cloudfunctions_function" "visionAPI" {
  name                  = "visionAPI"
  runtime               = "python39"
  source_archive_bucket = google_storage_bucket.staging-bucket.name
  source_archive_object = google_storage_bucket_object.visionAPI_gcs.name
  entry_point           = "entry_point"
  environment_variables = {
    PROJECT_ID      = var.project_id
    REJECTED_BUCKET = "${var.project_id}-flagged"
  }
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.visionapi.id
  }
}

# ======== videoIntelligenceAPI ========
# gcloud functions deploy videoIntelligenceAPI --runtime python39 --stage-bucket gs://dab-media-analyzer-dev-staging --trigger-topic videointelligenceservice --entry-point entry_point --timeout 540 --region europe-west1 --set-env-vars=PROJECT_ID=$PROJECT_ID,REJECTED_BUCKET=$PROJECT_ID-flagged


data "archive_file" "videoIntelligenceAPI_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../functions/videoIntelligenceAPI"
  output_path = local.videoIntelligenceAPI_zip
  excludes    = [".idea", "venv", ".vscode", "__pycache__", "examples"]
}

resource "google_storage_bucket_object" "videoIntelligenceAPI_gcs" {
  name   = "${data.archive_file.videoIntelligenceAPI_zip.output_md5}.zip"
  bucket = google_storage_bucket.staging-bucket.name
  source = local.videoIntelligenceAPI_zip
}


resource "google_cloudfunctions_function" "videoIntelligenceAPI" {
  name                  = "videoIntelligenceAPI"
  runtime               = "python39"
  timeout               = 540
  source_archive_bucket = google_storage_bucket.staging-bucket.name
  source_archive_object = google_storage_bucket_object.videoIntelligenceAPI_gcs.name
  entry_point           = "entry_point"
  environment_variables = {
    PROJECT_ID      = var.project_id
    REJECTED_BUCKET = "${var.project_id}-flagged"
  }
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.videoapi.id
  }
}

# ======== GCStoPubsub ========
# gcloud functions deploy insertIntoBigQuery --runtime python39 --stage-bucket gs://dab-media-analyzer-dev-staging --trigger-topic bqinsert --entry-point entry_point --region europe-west1 --set-env-vars=PROJECT_ID=$PROJECT_ID


data "archive_file" "insertIntoBigQuery_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../functions/insertIntoBigQuery"
  output_path = local.insertIntoBigQuery_zip
  excludes    = [".idea", "venv", ".vscode", "__pycache__", "examples"]
}

resource "google_storage_bucket_object" "insertIntoBigQuery_gcs" {
  name   = "${data.archive_file.insertIntoBigQuery_zip.output_md5}.zip"
  bucket = google_storage_bucket.staging-bucket.name
  source = local.insertIntoBigQuery_zip
}

resource "google_cloudfunctions_function" "insertIntoBigQuery" {
  name                  = "insertIntoBigQuery"
  runtime               = "python39"
  source_archive_bucket = google_storage_bucket.staging-bucket.name
  source_archive_object = google_storage_bucket_object.insertIntoBigQuery_gcs.name
  entry_point           = "entry_point"
  environment_variables = {
    PROJECT_ID = var.project_id
  }
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.insertbq.id
  }
}


########################  DLP  #####################






# create_DLP_job

data "archive_file" "create_DLP_job_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../functions/create_DLP_job"
  output_path = local.create_DLP_job_zip
  excludes    = [".idea", "venv", ".vscode", "__pycache__", "examples"]
}

resource "google_storage_bucket_object" "create_DLP_job_gcs" {
  source = local.create_DLP_job_zip
  bucket = google_storage_bucket.staging-dlp-bucket.name
  name   = "create_DLP_job-${data.archive_file.create_DLP_job_zip.output_md5}.zip"
}

resource "google_cloudfunctions_function" "create_DLP_job" {
  name                  = "create_DLP_job"
  runtime               = "python37"
  source_archive_bucket = google_storage_bucket.staging-dlp-bucket.name
  source_archive_object = google_storage_bucket_object.create_DLP_job_gcs.name
  entry_point           = "create_DLP_job"

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = "${var.project_id}-dlp-quarantine"
  }

  environment_variables = {
    PROJECT_ID     = var.project_id
    STAGING_BUCKET = "${var.project_id}-dlp-quarantine"
  }

}

# resolve_DLP
data "archive_file" "resolve_DLP_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../functions/resolve_DLP"
  output_path = local.resolve_DLP_zip
  excludes    = [".idea", "venv", ".vscode", "__pycache__", "examples"]
}


resource "google_storage_bucket_object" "resolve_DLP_gcs" {
  source = local.resolve_DLP_zip
  bucket = google_storage_bucket.staging-dlp-bucket.name
  name   = "resolve_DLP-${data.archive_file.resolve_DLP_zip.output_md5}.zip"
}

resource "google_cloudfunctions_function" "resolve_DLP" {
  name                  = "resolve_DLP"
  runtime               = "python37"
  source_archive_bucket = google_storage_bucket.staging-dlp-bucket.name
  source_archive_object = google_storage_bucket_object.resolve_DLP_gcs.name
  entry_point           = "resolve_DLP"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.classify-topic.id
  }
  environment_variables = {
    PROJECT_ID     = var.project_id
    STAGING_BUCKET = "${var.project_id}-dlp-quarantine"
  }
}
