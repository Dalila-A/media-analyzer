# project _id
variable "project_id" {
  type    = string
}

# dataset id
variable "DATASET_ID" {
  type    = string
  default = "intelligentcontentfilter"
}

# table name
variable "TABLE_NAME" {
  type    = string
  default = "filtered_content"
}

variable "project_nb" {
  type    = string
}
