import os
from google.cloud import bigquery as bq
import base64
import json




PROJECT_ID = os.getenv("PROJECT_ID")
DATASET_ID = "intelligentcontentfilter"
TABLE_NAME = "filtered_content"


# entry point function triggered by pubsub vision topic
# event = The Cloud Functions event which contains a message with the GCS file details

def local_entry_point():
    upload_notif_msg = open("bqInsert_topic.json","r")
    data = json.load(upload_notif_msg)

    main(data)

def entry_point(event, context):
    data_str = base64.b64decode(event['data']).decode('utf-8')
    data = json.loads(data_str)
    main(data)

# Function to validate the input 
# Checks the format of the notification sent to bq-insert topic

def validate_input(data):
	# if "bucket" empty or doesn't exist, raise error + log msg
    if "insertTimestamp" not in data or not data["insertTimestamp"]:
        raise ValueError(
            'insertTimestamp not provided. Make sure you have a "insertTimestamp" property in your request')

    # if "name" empty or doesn't exist, raise error + log msg
    elif "contentUrl" not in data or not data["contentUrl"]:
        raise ValueError(
            'ContentUrl not provided. Make sure you have a "contentUrl" property in your request')

    # if "contentType" empty or doesn't exist, raise error + log msg
    elif "contentType" not in data or not data["contentType"]:
        raise ValueError(
            'ContentType not provided. Make sure you have a "contentType" property in your request')

    # if "contentType" != video raise error + log msg
    elif ("video" not in data["contentType"]) and ("image" not in data["contentType"]):
        raise ValueError(
            'Unsupported ContentType provided. Make sure you upload an image or video which includes a "contentType" property of image or video in your request')

    # if "name" empty or doesn't exist, raise error + log msg
    elif "gcsUrl" not in data or not data["gcsUrl"]:
        raise ValueError(
            'GCSUrl not provided. Make sure you have a "gcsUrl" property in your request')


def insert_into_BQ(data):


    bq_client = bq.Client()
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_NAME}"

    errors = bq_client.insert_rows_json(table_id, [data])
    if errors:
        raise RuntimeError(f"row insert failed: {errors}")
    else:
        print(f"wrote 1 row to {table_id}")

    

def main(data):
    insert_into_BQ(data)

if __name__ == "__main__":
    local_entry_point()
