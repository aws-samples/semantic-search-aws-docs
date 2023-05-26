output "infra_region" {
  description = "The ingestion resources deployed in this AWS region."
  value       = var.infra_region
}

output "aws_docs" {
  description = "The deployment ingested these documents."
  value       = var.aws_docs
}

output "infra_tf_state_s3_bucket" {
  description = "The deployment used this S3 bucket for the state of the infrastructure deployment."
  value       = var.infra_tf_state_s3_bucket
}