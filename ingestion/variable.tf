variable "infra_tf_state_s3_bucket" {
  type        = string
  description = "The S3 Bucket where the remote TF state of the application infrastructure is stored"
}

variable "infra_tf_state_s3_key" {
  type        = string
  description = "The S3 key where the remote TF state of the application nfrastructure is stored"
}

variable "infra_region" {
  type        = string
  description = "The AWS region where to the application infrastructure is deployed, e.g. 'us-east-1'."
}

#variable "aws_docs" {
#  type        = string
#  description = "The AWS Documentation to be ingested. Use 'full' or specific documents like 'amazon-eks-user-guide' "
#}

variable "docs_src" {
  type        = string
  description = "One of the following three options: 1. a path to the local directory that contains documents or 2. an url that points to a archive (zip, gz or tar.gz), or 3. AWS documentation to be ingested, use 'full' or specific documents like 'amazon-eks-user-guide'. This docs_src variable will specifies the documents to ingest into the Amazon OpenSearch index."
  default = "amazon-eks-user-guide"
}

variable "script_name" {
  type = string
  description = "The script that the ingestion container runs to ingest the documents into the Amazon OpenSearch index. Set to 'run_ingestion_local' to ingest documents from a local directory (set variable docs_src to local path). Set to 'run_ingestion_awsdocs_local' to ingest the AWS documentation (set docs_src to AWS documentation). Set to 'run_ingestion_url' to ingest documents from an url (set docs_src to the url)."
  default = "run_ingestion_awsdocs_local"
}