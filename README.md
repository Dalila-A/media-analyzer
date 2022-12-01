# Scanning User-generated Content Using the Cloud Video Intelligence, Cloud Vision and Cloud DLP APIs 

Most applications require a certain amount of image, video or text processing. In this architecture let’s assume a blogging website where users generate content in the form of videos, images and text. 

The Cloud Video Intelligence and Cloud Vision APIs offer you a scalable and serverless way to implement intelligent image and video filtering, accelerating submission processing. If you use the safe-search feature in the Vision API solution and the explicit content detection feature in the Video Intelligence API, you can eliminate images and videos that are identified as unsafe or undesirable content before further processing.

The Cloud DLP API allows you to discover, classify, and protect your most sensitive data.

# Objectives

We're going to deploy 2 pipelines :
- 1st pipeline : image & video processing
- 2nd pipeline : text processing

## Requirements

We'll need image, video and text files that you can upload into the lab for analysis. Ideally they would be of different types - with people whose faces can be seen, no people, landscape, close-ups - so we can see how the image analysis treats the image. We’ll also need text (csv, txt, …) with fake PII so we can analyze it with DLP.

## High level Architecture
The following diagrams outline the high-level architecture

# PIPELINE 1 : Video & Image processing

For this pipeline, we will use **Terraform** to :

- Create the supporting Cloud Storage buckets, Cloud Pub/Sub topics, and Cloud Storage Pub/Sub Notifications. 
- Deploy four Cloud Functions in Python.
- Create the supporting BigQuery dataset and table.

## Cloud Storage : Buckets & notifications

Cloud Storage buckets provide a storage location for uploading your images and videos. We will create 4 different buckets.
- a bucket for storing your uploaded images and video files using the **IV_BUCKET_NAME** environment variable
- a bucket for storing your filtered image and video files using the **FILTERED_BUCKET_NAME** environment variable
- a bucket for storing your flagged image and video files using the **FLAGGED_BUCKET_NAME** environment variable
- a bucket for your Cloud Functions to use as a staging location using the **STAGING_BUCKET_NAME** environment variable
- We also need to create a notification called **OBJECT_FINALIZE** that is triggered only when a new object is placed in the Cloud Storage file upload bucket **IV_BUCKET_NAME**.

## Cloud Pub/Sub 
Cloud Pub/Sub topics are used for Cloud Storage notification messages and for messages between the Cloud Functions. We need to create 4 topics :
- a topic to receive Cloud Storage notifications whenever a file is uploaded to Cloud Storage. The default value will be set to **upload_notification** and save it in an environment variable since it will be used later.
- a topic to receive messages from the Vision API. The default value will be set to **visionapiservice**.
- a topic to receive your messages from the Video Intelligence API. The default value will be set to **videointelligenceservice**.
- a topic to receive messages to store in BigQuery. The default value will be set to **bqinsert**.

## Cloud Functions
The Cloud functions will be triggered by Pub/Sub events from previous topics. 
- **GCSToPubSub** : triggered by a PubSub event from **upload-notification** topic to check the format of the file. Depending on the result, the file is moved from the source bucket to the destination bucket.
- **visionAPI** : triggered by a PubSub event from **visionapiservice** topic to check the format & annotate the file. Depending on the result, the file is moved from the source bucket to the destination bucket.
- **videoIntelligenceAPI** : triggered by a PubSub event from **videointelligenceservice** topic to check the format & annotate the file. Depending on the result, the file is moved from the source bucket to the destination bucket.
- **insertIntoBigquery** : triggered by a PubSub event from **bqInsert** topic. The message contains the annotations' result which is loaded into BQ in JSON format.

## BigQuery Dataset
The results of the Vision and Video Intelligence APIs will be stored in BigQuery. The default dataset and table names are set to **intelligentcontentfilter** and **filtered_content**.
Ths schema is defined in the **table.tf** file.
