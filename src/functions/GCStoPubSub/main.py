import os
import json
import base64
from google.cloud import storage
from google.cloud import pubsub_v1

PROJECT_ID = os.getenv("PROJECT_ID")
RESULT_BUCKET = os.getenv("RESULT_BUCKET")
VISION_TOPIC = "visionapiservice"
VIDEOINTELLIGENCE_TOPIC = "videointelligenceservice"

# Function for local testing
def local_entry_point():
    upload_notif_msg = open("message1.json","r")
    data = json.load(upload_notif_msg)

    main(data)

# Entry point
def entry_point(event, context):
    data_str = base64.b64decode(event['data']).decode('utf-8')
    data = json.loads(data_str)
    main(data)

# Checks the format of the file uploaded in upload-bucket
def validate_input(data):
	# if "bucket" empty or doesn't exist, raise error + log msg
    if "bucket" not in data or not data["bucket"]:
        raise ValueError(
            'Bucket not provided. Make sure you have a "bucket" property in your request')

    # if "name" empty or doesn't exist, raise error + log msg
    elif "name" not in data or not data["name"]:
        raise ValueError(
            'Filename not provided. Make sure you have a "name" property in your request')

    # if "contentType" empty or doesn't exist, raise error + log msg
    elif "contentType" not in data or not data["contentType"]:
        raise ValueError(
            'ContentType not provided. Make sure you have a "contentType" property in your request')

    # if "contentType" != video or image, raise error + log msg
    elif ("video" not in data["contentType"]) and ("image" not in data["contentType"]):
        raise ValueError(
            'Unsupported ContentType provided. Make sure you upload an image or video which includes a "contentType" property of image or video in your request')



# Function to Move file from src bucket to dest bucket & Delete file from src bucket
def move_file(src_blob_name, src_bucket_name, dest_bucket_name):
    storage_client = storage.Client()

    dest_blob_name = src_blob_name

    source_bucket = storage_client.bucket(src_bucket_name)
    source_blob = source_bucket.blob(src_blob_name)
    destination_bucket = storage_client.bucket(dest_bucket_name)
    source_bucket.copy_blob(source_blob, destination_bucket, dest_blob_name)
    source_blob.delete()

# Function to construct msg to PubSub :
# send msg to topic Vision if file is an image
# send msg to topic Intelligence if file is a video

def publish_result(topic_name, data):
    # instanciate a publicher client
    publisher = pubsub_v1.PublisherClient()

    # create the msg to send to the topic
    msg_data = {
        "contentType": data["contentType"],
        "gcsUrl": "gs://" + RESULT_BUCKET + "/" + data["name"],
        "gcsBucket": RESULT_BUCKET,
        "gcsFile": data["name"]
    }

    # retrieve topic long name & convert the message into a JSON string
    # topic_long_name="projects/{project_id}/topics/{topic}".format(project_id=PROJECT_ID, topic=topic_name)
    topic_long_name = publisher.topic_path(PROJECT_ID, topic_name)
    encoded_data = json.dumps(msg_data).encode("utf-8")

	# future indicates if the msg was succesfully published
	# returns message ID unless an error occurs
    future = publisher.publish(topic_long_name, encoded_data)
    (future.result())

def main(data):
    
	# Step 1 : validate data coming from storage event
	validate_input(data)

	# Step 2 :  We move file to RESULT_BUCKET = bucket-filtered
	move_file(data["name"],data["bucket"], RESULT_BUCKET)
	print("FILE MOVED SUCCESSFULLY to {}".format(RESULT_BUCKET))

	# Step 3 : Send message to appropriate topic according to content type
	if "image" in data["contentType"]:	
	    publish_result(VISION_TOPIC, data)
	elif "video" in data["contentType"]:
	    publish_result(VIDEOINTELLIGENCE_TOPIC, data)
	else:
		print("Incorrect file type")
    

if __name__ == "__main__":
    local_entry_point()
