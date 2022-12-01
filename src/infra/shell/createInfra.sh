set -e
set -u

# Initialize environment variables
export PROJECT_ID=$1

export IV_BUCKET_NAME=${PROJECT_ID}-upload
export FILTERED_BUCKET_NAME=${PROJECT_ID}-filtered
export FLAGGED_BUCKET_NAME=${PROJECT_ID}-flagged
export STAGING_BUCKET_NAME=${PROJECT_ID}-staging
export DATASET_ID=intelligentcontentfilter
export TABLE_NAME=filtered_content

# create GCS buckets
gsutil mb gs://${IV_BUCKET_NAME}
gsutil mb gs://${FILTERED_BUCKET_NAME}
gsutil mb gs://${FLAGGED_BUCKET_NAME}
gsutil mb gs://${STAGING_BUCKET_NAME}

# create Pusub topics
gcloud pubsub topics create upload_notification
gcloud pubsub topics create visionapiservice
gcloud pubsub topics create videointelligenceservice
gcloud pubsub topics create bqinsert

# create GCS to Pubsub notification
gsutil notification create -t upload_notification -f json -e OBJECT_FINALIZE gs://${IV_BUCKET_NAME}

# download the code from the bucket
gsutil -m cp -r gs://spls/gsp138/cloud-functions-intelligentcontent-nodejs .

# change directory
cd cloud-functions-intelligentcontent-nodejs

# create the BQ dataset & table
bq --project_id ${PROJECT_ID} mk ${DATASET_ID}
bq --project_id ${PROJECT_ID} mk --schema intelligent_content_bq_schema.json -t ${DATASET_ID}.${TABLE_NAME}

# update config.json to use the specifis ressources (GCS buckets, topics, dataset, table)
sed -i "s/\[PROJECT-ID\]/$PROJECT_ID/g" config.json
sed -i "s/\[FLAGGED_BUCKET_NAME\]/$FLAGGED_BUCKET_NAME/g" config.json
sed -i "s/\[FILTERED_BUCKET_NAME\]/$FILTERED_BUCKET_NAME/g" config.json
sed -i "s/\[DATASET_ID\]/$DATASET_ID/g" config.json
sed -i "s/\[TABLE_NAME\]/$TABLE_NAME/g" config.json

# deploy GCStoPubsub function
gcloud functions deploy GCStoPubsub --runtime nodejs10 --stage-bucket gs://${STAGING_BUCKET_NAME} --trigger-topic upload_notification --entry-point GCStoPubsub

# deploy visionAPI function
gcloud functions deploy visionAPI --runtime nodejs10 --stage-bucket gs://${STAGING_BUCKET_NAME} --trigger-topic visionapiservice --entry-point visionAPI

# deploy videoIntelligenceAPI function
gcloud functions deploy videoIntelligenceAPI --runtime nodejs10 --stage-bucket gs://${STAGING_BUCKET_NAME} --trigger-topic videointelligenceservice --entry-point videoIntelligenceAPI --timeout 540

# deploy insertIntoBigQuery function
gcloud functions deploy insertIntoBigQuery --runtime nodejs10 --stage-bucket gs://${STAGING_BUCKET_NAME} --trigger-topic bqinsert --entry-point insertIntoBigQuery