set -e
set -u

# Initialize environment variables
export PROJECT_ID=$1
export DATASET_ID=intelligentcontentfilter
export IV_BUCKET_NAME=${PROJECT_ID}-upload
export FILTERED_BUCKET_NAME=${PROJECT_ID}-filtered
export FLAGGED_BUCKET_NAME=${PROJECT_ID}-flagged
export STAGING_BUCKET_NAME=${PROJECT_ID}-staging


# delete insertIntoBigQuery function
gcloud functions delete insertIntoBigQuery --project $PROJECT_ID --quiet

# delete videoIntelligenceAPI function
gcloud functions delete videoIntelligenceAPI --project $PROJECT_ID --quiet

# delete visionAPI function
gcloud functions delete visionAPI --project $PROJECT_ID --quiet

#delete GCStoPubsub function
gcloud functions delete GCStoPubsub --project $PROJECT_ID --quiet

# delete the BQ dataset & table
bq rm -r -f $PROJECT_ID:$DATASET_ID

# delete GCS to Pubsub notification
gsutil notification delete gs://${IV_BUCKET_NAME}

# delete Pusub topics 
gcloud pubsub topics delete upload_notification --project $PROJECT_ID --quiet
gcloud pubsub topics delete visionapiservice --project $PROJECT_ID --quiet
gcloud pubsub topics delete videointelligenceservice --project $PROJECT_ID --quiet
gcloud pubsub topics delete bqinsert --project $PROJECT_ID --quiet

# delete GCS buckets
gsutil -m rm -r gs://${IV_BUCKET_NAME}
gsutil -m rm -r gs://${FILTERED_BUCKET_NAME}
gsutil -m rm -r gs://${FLAGGED_BUCKET_NAME}
gsutil -m rm -r gs://${STAGING_BUCKET_NAME}
