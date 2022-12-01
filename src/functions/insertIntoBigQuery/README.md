# Objectives
- Function triggered by a PubSub event from bqInsert topic.
- The message contains the result of the annotations made by Visin API or Intelligence API.
- This result is inserted into BigQuery

# Methods
- ``entry_point()``: retrieves the event published in bqInsert topic & loads it in JSON format. The event contains the result of the annotations made by Visin API or Intelligence API
- ``validate_input()``: validates the format of the file
- ``insert_into_BQ``: inserts the result into BQ