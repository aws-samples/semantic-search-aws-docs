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

variable "aws_docs" {
  type        = string
  description = "The AWS Documentation to be ingested. Use 'full' or specific documents like 'amazon-eks-user-guide' "
}

variable "docs_dir" {
  type        = string
  description = "The local directory that contains documents to ingest into the Amazon OpenSearch index."
  default = "mydocs/data"
}

variable "script_name" {
  type = string
  description = "The script that the ingestion container runs to ingest the documents into the Amazon OpenSearch index. Set to 'run_ingestion' to ingest documents from a local directory (see also variable docs_dir). Set to 'run_ingestion_awsdocs' to ingest the AWS documentation (see also aws_docs)."
  default = "run_ingestion_awsdocs"
}