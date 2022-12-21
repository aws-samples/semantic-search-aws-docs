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