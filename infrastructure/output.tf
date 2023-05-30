output "loadbalancer_url" {
  description = "Application Loadbalancer endpoint url where you can read the frontend after deploying."
  value       = aws_alb.main.dns_name
}

output "opensearch_endpoint" {
  description = "Domain-specific endpoint used to submit index, search, and data upload requests."
  value       = aws_elasticsearch_domain.es.endpoint
}

output "opensearch_password" {
  sensitive   = true
  description = "Password for opensearch endpoint"
  value       = random_password.password.result
}

output "security_group_for_open_search_access" {
  value = aws_security_group.search_api.id
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}
output "region" {
  value = data.aws_region.current.name
}

output "opensearch_secret" {
  value = aws_secretsmanager_secret.opensearch.arn
}

output "ingestion_job_role" {
  value = aws_iam_role.search_api.arn
}

output "index_name" {
  value = var.index_name
}