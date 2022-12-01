# upload_notification
resource "google_pubsub_topic" "notification" {
  name = "upload_notification"
}

# visionapiservice
resource "google_pubsub_topic" "visionapi" {
  name = "visionapiservice"
}

# videointelligenceservice
resource "google_pubsub_topic" "videoapi" {
  name = "videointelligenceservice"
}

# bqinsert
resource "google_pubsub_topic" "insertbq" {
  name = "bqinsert"
}

##################### DLP ###################

# classify topic
resource "google_pubsub_topic" "classify-topic" {
  name = "classify-topic"
}

# classify pull subscription
resource "google_pubsub_subscription" "classify-sub" {
  name  = "classify-sub"
  topic = google_pubsub_topic.classify-topic.name
}