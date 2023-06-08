output "infra_region" {
  description = "The ingestion resources deployed in this AWS region."
  value       = var.infra_region
}

output "docs_src" {
  description = "The deployment ingested these documents."
  value       = var.docs_src
}

output "infra_tf_state_s3_bucket" {
  description = "The deployment used this S3 bucket for the state of the infrastructure deployment."
  value       = var.infra_tf_state_s3_bucket
}