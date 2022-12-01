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
""" Pub/Sub topic to notify once the  DLP job completes."""
PUB_SUB_TOPIC = 'classify-topic'
"""The minimum_likelihood (Enum) required before returning a match"""
"""For more info visit: https://cloud.google.com/dlp/docs/likelihood"""
MIN_LIKELIHOOD = 'POSSIBLE'
"""The maximum number of findings to report (0 = server maximum)"""
MAX_FINDINGS = 0
"""The infoTypes of information to match"""
"""For more info visit: https://cloud.google.com/dlp/docs/concepts-infotypes"""
INFO_TYPES = [
    'FIRST_NAME', 'PHONE_NUMBER', 'EMAIL_ADDRESS', 'US_SOCIAL_SECURITY_NUMBER'
]

# End of User-configurable Constants
# ----------------------------------

# Initialize the Google Cloud client libraries
dlp = dlp.DlpServiceClient()
storage_client = storage.Client()
publisher = pubsub.PublisherClient()
subscriber = pubsub.SubscriberClient()


def create_DLP_job(data, done):
  """This function is triggered by new files uploaded to the designated Cloud Storage quarantine bucket.

       It creates a dlp job for the uploaded file.
    Arg:
       data: The Cloud Storage Event
    Returns:
        None. Debug information is printed to the log.
    """
  # Get the targeted file in the quarantine bucket
  file_name = data['name']
  print('Function triggered for file [{}]'.format(file_name))

  # Prepare info_types by converting the list of strings (INFO_TYPES) into a list of dictionaries
  info_types = [{'name': info_type} for info_type in INFO_TYPES]

  # Convert the project id into a full resource id.
  parent = f"projects/{PROJECT_ID}"

  # Construct the configuration dictionary.
  inspect_job = {
      'inspect_config': {
          'info_types': info_types,
          'min_likelihood': MIN_LIKELIHOOD,
          'limits': {
              'max_findings_per_request': MAX_FINDINGS
          },
      },
      'storage_config': {
          'cloud_storage_options': {
              'file_set': {
                  'url':
                      'gs://{bucket_name}/{file_name}'.format(
                          bucket_name=STAGING_BUCKET, file_name=file_name)
              }
          }
      },
      'actions': [{
          'pub_sub': {
              'topic':
                  'projects/{project_id}/topics/{topic_id}'.format(
                      project_id=PROJECT_ID, topic_id=PUB_SUB_TOPIC)
          }
      }]
  }

  # Create the DLP job and let the DLP api processes it.
  try:
    dlp.create_dlp_job(parent=(parent), inspect_job=(inspect_job))
    print('Job created by create_DLP_job')
  except Exception as e:
    print(e)