variable "network_name" {
  type = string
}

#variables Prometheus
variable "prometheus_image" {
  type = string
}

variable "prometheus_container_name" {
  type = string
}

variable "prometheus_scrape_targets" {
  type = list(string)
}

variable "prometheus_external_port" {
  type = number
  default = 9090
}

variable "prometheus_internal_port" {
  type = number
  default = 9090
}


#variables Grafana
variable "grafana_image" {
  type = string
}

variable "grafana_container_name" {
  type = string
}

variable "grafana_external_port" {
  type = number
  default = 3000
}

variable "grafana_internal_port" {
  type = number
  default = 3000
}

variable "grafana_admin_user" {
  type = string
}

variable "grafana_admin_password" {
  type = string
}

#variables cAdvisor
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

#variables Loki
variable "loki_image" {
  type = string
}

variable "loki_container_name" {
  type = string
}

variable "loki_internal_port" {
  type = number
  default = 3100
}

variable "loki_external_port" {
  type = number
}


#variables Promtail
variable "promtail_image" {
  type = string
}

variable "promtail_container_name" {
  type = string
}


#variables Alertmanager
variable "alertmanager_image" {
  type = string
}

variable "alertmanager_container_name" {
  type = string
}

variable "alertmanager_internal_port" {
  type = number
  default = 9093
}

variable "alertmanager_external_port" {
  type = number
}

variable "alerting_enabled" {
  type    = bool
  default = true
}