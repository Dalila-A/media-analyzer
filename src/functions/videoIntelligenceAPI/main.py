import os
from google.cloud import videointelligence as video
from google.cloud import storage
from google.cloud import pubsub_v1
import base64
import json
import calendar
import time
from enum import Enum

from google.cloud.videointelligence_v1.types.video_intelligence import Likelihood

PROJECT_ID = os.getenv("PROJECT_ID")
BIGQUERY_TOPIC = "bqinsert"
REJECTED_BUCKET = os.getenv("REJECTED_BUCKET")
GCS_AUTH_BROWSER_URL_BASE = "https://storage.cloud.google.com/"



# entry point function triggered by pubsub video topic
# event = The Cloud Functions event which contains a message with the GCS file details

def local_entry_point():
    upload_notif_msg = open("upload_notif_msg.json","r")
    data = json.load(upload_notif_msg)

    main(data)

def entry_point(event, context):
    data_str = base64.b64decode(event['data']).decode('utf-8')
    data = json.loads(data_str)
    main(data)

# Function to validate the input 
# Checks the format of the notification sent to upload-notofication topic

def validate_input(data):
	# if "bucket" empty or doesn't exist, raise error + log msg
    if "gcsBucket" not in data or not data["gcsBucket"]:
        raise ValueError(
            'Bucket not provided. Make sure you have a "bucket" property in your request')

    # if "name" empty or doesn't exist, raise error + log msg
    elif "gcsFile" not in data or not data["gcsFile"]:
        raise ValueError(
            'Filename not provided. Make sure you have a "name" property in your request')

    # if "contentType" empty or doesn't exist, raise error + log msg
    elif "contentType" not in data or not data["contentType"]:
        raise ValueError(
            'ContentType not provided. Make sure you have a "contentType" property in your request')

    # if "contentType" != video raise error + log msg
    elif ("video" not in data["contentType"]):
        raise ValueError(
            'Unsupported ContentType provided. Make sure you upload an image or video which includes a "contentType" property of image or video in your request')

    # if "name" empty or doesn't exist, raise error + log msg
    elif "gcsUrl" not in data or not data["gcsUrl"]:
        raise ValueError(
            'GCSUrl not provided. Make sure you have a "gcsUrl" property in your request')


# Function to annotate video with VideoIntelligence API
# uri = uri of the file located in GCS bucket filtered

def annotate_video(uri):

# Instanciate client
    video_client = video.VideoIntelligenceServiceClient()

    request = {
        "input_uri": uri,
        "features": ["LABEL_DETECTION", "EXPLICIT_CONTENT_DETECTION"]
    }

    # Send request
    operation = video_client.annotate_video(request)

    # Get result 
    result = operation.result(timeout=180)

    return result


# Function to create BQ Object

def create_bqInsertObj(annotate_video_result, data):

    # construct labels to append to BQ object
    segment_labels = annotate_video_result.annotation_results[0].segment_label_annotations

    labels =  []
    for i, segment_label in enumerate(segment_labels):
        label = {"name" : segment_label.entity.description}
        labels.append(label)
    print(json.dumps(labels, indent=2))
        
    # construct safesearch results to append to BQ object
    safesearch_results = []
    for safesearch in annotate_video_result.annotation_results[0].explicit_annotation.frames:
        likelihood = video.Likelihood(safesearch.pornography_likelihood)
        flaggedTypeObj = {
        "flaggedType" : "adult",
        "likelihood" :  likelihood.name
    }
    safesearch_results.append(flaggedTypeObj)

    # get timestamp
    timestamp = calendar.timegm(time.gmtime())

    # create BQ object
    bqInsertObj = {
        'gcsUrl' : data["gcsUrl"] ,
        'contentUrl' : GCS_AUTH_BROWSER_URL_BASE + data["gcsBucket"] + "/" + data["gcsFile"],
        'contentType' : data["contentType"],
        "insertTimestamp" : timestamp,
        "labels" : labels,
        "safeSearch" : safesearch_results
        
    }
    return bqInsertObj, likelihood.name
    

# Checks whether the SafeSearch value is POSSIBLE, LIKELY, OR VERY_LIKELY and returns true if so, otherwise false

def check_safeSearch_likelihood(likelihood):
    likelihood_names = ('POSSIBLE','LIKELY','VERY_LIKELY')
    if likelihood in likelihood_names:
        return True

# Function to move a file from 1 GCS bucket to another
def move_file(src_blob_name, src_bucket_name, dest_bucket_name):
    storage_client = storage.Client()

    dest_blob_name = src_blob_name

    source_bucket = storage_client.bucket(src_bucket_name)
    source_blob = source_bucket.blob(src_blob_name)
    destination_bucket = storage_client.bucket(dest_bucket_name)
    source_bucket.copy_blob(source_blob, destination_bucket, dest_blob_name)
    source_blob.delete()

# Publishes the result to bqinsert topic
def publish_result(topic_name, data):

    # instanciate a publicher client
    publisher = pubsub_v1.PublisherClient()

    # retrieve topic long name & convert the message into a JSON string
    topic_long_name = publisher.topic_path(PROJECT_ID, topic_name)
    encoded_data = json.dumps(data).encode("utf-8")

	# future indicates if the msg was succesfully published
	# returns message ID unless an error occurs
    future = publisher.publish(topic_long_name, encoded_data)
    future.result()

def main(data):
    """The data is received from GCStoPubsub function through pub/sub in the following format:
    {
        "contentType": "video/quicktime",
        "gcsUrl": "gs://dab-media-analyzer-filtered/video2.mov",
        "gcsBucket": "dab-media-analyzer-filtered",
        "gcsFile": "video2.mov"
    }
    """
    validate_input(data)

    annotate_video_result = annotate_video(data["gcsUrl"])

    bqInsertObj, likelihood = create_bqInsertObj(annotate_video_result, data)

    if check_safeSearch_likelihood(likelihood):
        move_file(data["gcsFile"],data["gcsBucket"], REJECTED_BUCKET)  
        
        ####################### TODO ####################
        #       UPDATE URI & URL IN bqInsertObj         #
        #################################################

    publish_result(BIGQUERY_TOPIC, bqInsertObj)


if __name__ == "__main__":

    local_entry_point()
