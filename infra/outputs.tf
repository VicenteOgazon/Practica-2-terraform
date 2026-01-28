output "prometheus_url" {
  value = "http://localhost:${var.prometheus_external_port}"
}

output "grafana_url" {
  value = "http://localhost:${var.grafana_external_port}"
}

output "minio_api_url" {
  value = "http://localhost:${var.minio_api_external_port}"
}

output "minio_console_url" {
  value = "http://localhost:${var.minio_console_external_port}"
}

output "workspace" {
  value = terraform.workspace
}

output "lb_url" {
  value = module.lb.url
}

output "web_replicas" {
  value = var.web_replicas
}

output "minio_api_port" {
  description = "Puerto externo del API de MinIO"
  value       = var.minio_api_external_port
}

output "minio_bucket" {
  description = "Bucket de estáticos del entorno"
  value       = var.environment == "production" ? "static-prod" : "static-dev"
}