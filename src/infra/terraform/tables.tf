resource "google_bigquery_table" "table" {
  dataset_id = var.DATASET_ID
  table_id   = var.TABLE_NAME
  deletion_protection = false
  schema     = <<EOF
[
    {
        "mode": "REQUIRED",
        "name": "gcsUrl",
        "type": "STRING"
    },
    {
        "mode": "REQUIRED",
        "name": "contentUrl",
        "type": "STRING"
    },

    {
        "mode": "REQUIRED",
        "name": "contentType",
        "type": "STRING"
    },
    {
        "mode": "REQUIRED",
        "name": "insertTimestamp",
        "type": "TIMESTAMP"
    },
    {
        "mode": "REPEATED",
        "name": "labels",
        "type": "RECORD",
        "fields": [
            {
                "mode": "NULLABLE",
                "name": "name",
                "type": "STRING"
            }
        ]
    },
    {
        "mode": "REPEATED",
        "name": "safeSearch",
        "type": "RECORD",
        "fields": [
            {
                "mode": "NULLABLE",
                "name": "flaggedType",
                "type": "STRING"
            },
            {
                "mode": "NULLABLE",
                "name": "likelihood",
                "type": "STRING"
            }
        ]
    }
]
EOF

}