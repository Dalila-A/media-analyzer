""" Copyright 2018, Google, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless  required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Authors: Yuhan Guo, Zhaoyuan Sun, Fengyi Huang, Weimu Song.
Date:    October 2018

"""

from google.cloud import dlp
from google.cloud import storage
from google.cloud import pubsub
import os


# ----------------------------
#  User-configurable Constants

PROJECT_ID = os.getenv('PROJECT_ID')
"""The bucket the to-be-scanned files are uploaded to."""
STAGING_BUCKET = os.getenv('STAGING_BUCKET')
"""The bucket to move "sensitive" files to."""
SENSITIVE_BUCKET = PROJECT_ID + '-dlp-sensitive'
"""The bucket to move "non sensitive" files to."""
NONSENSITIVE_BUCKET = PROJECT_ID + '-dlp-nonsensitive'

# End of User-configurable Constants
# ----------------------------------

# Initialize the Google Cloud client libraries
dlp = dlp.DlpServiceClient()
storage_client = storage.Client()
publisher = pubsub.PublisherClient()
subscriber = pubsub.SubscriberClient()


def resolve_DLP(data, context):
  """This function listens to the pub/sub notification from create_DLP function.

    As soon as it gets pub/sub notification, it picks up results from the
    DLP job and moves the file to sensitive bucket or nonsensitive bucket
    accordingly.
    Args:
        data: The Cloud Pub/Sub event

    Returns:
        None. Debug information is printed to the log.
    """
  # Get the targeted DLP job name that is created by the create_DLP_job function
  job_name = data['attributes']['DlpJobName']
  print('Received pub/sub notification from DLP job: {}'.format(job_name))

  # Get the DLP job details by the job_name
  job = dlp.get_dlp_job(request = {'name': job_name})
  print('Job Name:{name}\nStatus:{status}'.format(
      name=job.name, status=job.state))

  # Fetching Filename in Cloud Storage from the original dlpJob config.
  # See defintion of "JSON Output' in Limiting Cloud Storage Scans':
  # https://cloud.google.com/dlp/docs/inspecting-storage

  file_path = (
      job.inspect_details.requested_options.job_config.storage_config
      .cloud_storage_options.file_set.url)
  file_name = os.path.basename(file_path)

  info_type_stats = job.inspect_details.result.info_type_stats
  source_bucket = storage_client.get_bucket(STAGING_BUCKET)
  source_blob = source_bucket.blob(file_name)
  if (len(info_type_stats) > 0):
    # Found at least one sensitive data
    for stat in info_type_stats:
      print('Found {stat_cnt} instances of {stat_type_name}.'.format(
          stat_cnt=stat.count, stat_type_name=stat.info_type.name))
    print('Moving item to sensitive bucket')
    destination_bucket = storage_client.get_bucket(SENSITIVE_BUCKET)
    source_bucket.copy_blob(source_blob, destination_bucket,
                            file_name)  # copy the item to the sensitive bucket
    source_blob.delete()  # delete item from the quarantine bucket

  else:
    # No sensitive data found
    print('Moving item to non-sensitive bucket')
    destination_bucket = storage_client.get_bucket(NONSENSITIVE_BUCKET)
    source_bucket.copy_blob(
        source_blob, destination_bucket,
        file_name)  # copy the item to the non-sensitive bucket
    source_blob.delete()  # delete item from the quarantine bucket
  print('{} Finished'.format(file_name))
