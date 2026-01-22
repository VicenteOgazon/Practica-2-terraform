variable "network_name" {
  type = string
}

variable "environment" {
  type = string
}

# Web
variable "app_image" {
  type = string
}

variable "web_container_name" {
  type = string
}

variable "web_internal_port" {
  type = number
}

variable "web_replicas" {
  type = number
}

# DB
variable "db_image" {
  type = string
}

variable "db_init" {
  type = string
}

variable "volume_name" {
  type = string
}

variable "db_container_name" {
  type = string
}

variable "db_root_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

# Cache (opcional)
variable "enable_cache" {
  type    = bool
  default = false
}

variable "cache_image" {
  type    = string
  default = null
}

variable "cache_container_name" {
  type    = string
  default = ""
}

variable "cache_internal_port" {
  type    = number
  default = 6379
}

variable "cache_external_port" {
  type    = number
  default = null
}

# Load Balancer
variable "lb_image" {
  type = string
}

variable "lb_container_name" {
  type = string
}

variable "lb_listen_port" {
  type = number
}

# Prometheus
variable "prometheus_container_name" {
  type = string
}

variable "prometheus_image" {
  type = string
}

variable "prometheus_internal_port" {
  type = number
}

variable "prometheus_external_port" {
  type = number
}

# Grafana
variable "grafana_image" {
  type = string
}

variable "grafana_container_name" {
  type = string
}

variable "grafana_internal_port" {
  type = number
}

variable "grafana_external_port" {
  type = number
}

variable "grafana_admin_user" {
  type = string
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

# cAdvisor
variable "cadvisor_container_name" {
  type = string
}

variable "cadvisor_image" {
  type = string
}

variable "cadvisor_internal_port" {
  type = number
}

variable "cadvisor_external_port" {
  type = number
}

# Loki
variable "loki_container_name" {
  type = string
}

variable "loki_image" {
  type = string
}

variable "loki_internal_port" {
  type    = number
  default = 3100
}

variable "loki_external_port" {
  type = number
}

# Promtail
variable "promtail_container_name" {
  type = string
}

variable "promtail_image" {
  type = string
}

# Alerting (solo prod)
variable "alerting_enabled" {
  type    = bool
  default = false
}

variable "alertmanager_image" {
  type = string
}

variable "alertmanager_container_name" {
  type = string
}

variable "alertmanager_internal_port" {
  type    = number
  default = 9093
}

variable "alertmanager_external_port" {
  type = number
}

# MinIO
variable "minio_image" {
  type = string
}

variable "minio_container_name" {
  type = string
}

variable "minio_access_key" {
  type = string
}

variable "minio_secret_key" {
  type      = string
  sensitive = true
}

variable "minio_api_internal_port" {
  type    = number
  default = 9000
}

variable "minio_api_external_port" {
  type = number
}

variable "minio_console_internal_port" {
  type    = number
  default = 9001
}

variable "minio_console_external_port" {
  type = number
}