output "lb_url" {
  value = "http://localhost:${var.lb_listen_port}"
}

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