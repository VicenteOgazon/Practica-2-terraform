terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
    local = {
      source  = "hashicorp/local" # Necesario para gestionar recursos locales
      version = "~> 2.4"
    }
  }
}

locals {
  prometheus_config = templatefile("${path.module}/prometheus.yml.tpl", {
    scrape_targets     = var.prometheus_scrape_targets
    cadvisor_name      = var.cadvisor_container_name
    cadvisor_port      = var.cadvisor_internal_port
    alerting_enabled   = var.alerting_enabled
    alertmanager_host  = var.alertmanager_container_name
    alertmanager_port  = var.alertmanager_internal_port
  })

  promtail_config = templatefile("${path.module}/promtail-config.yml.tpl", {
    loki_host = var.loki_container_name
    loki_port = var.loki_internal_port
  })
}


# Fichero de configuración de Prometheus
resource "local_file" "prometheus_config" {
  content  = local.prometheus_config
  filename = abspath("${path.module}/${var.prometheus_container_name}-generated-prometheus.yml")
}

resource "local_file" "promtail_config" {
  content  = local.promtail_config
  filename = abspath("${path.module}/${var.promtail_container_name}-generated-promtail.yml")
}

# Volúmenes para datos
resource "docker_volume" "prometheus_data" {
  name = "${var.prometheus_container_name}_data"
}

resource "docker_volume" "grafana_data" {
  name = "${var.grafana_container_name}_data"
}

resource "docker_volume" "loki_data" {
  name = "${var.loki_container_name}_data"
}

# Contenedor Prometheus
resource "docker_container" "prometheus" {
  name  = var.prometheus_container_name
  image = var.prometheus_image

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = var.prometheus_internal_port
    external = var.prometheus_external_port
  }

  volumes {
    host_path      = abspath(local_file.prometheus_config.filename)
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }
  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  volumes {
    host_path      = abspath("${path.module}/alert-rules.yml")
    container_path = "/etc/prometheus/alert-rules.yml"
    read_only      = true
  }

}

# Contenedor Grafana
resource "docker_container" "grafana" {
  name  = var.grafana_container_name
  image = var.grafana_image

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = var.grafana_internal_port
    external = var.grafana_external_port
  }

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  env = [
    "GF_SECURITY_ADMIN_USER=${var.grafana_admin_user}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
  ]
}

# Contenedor cAdvisor
resource "docker_container" "cadvisor" {
  name  = var.cadvisor_container_name
  image = var.cadvisor_image

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = var.cadvisor_internal_port
    external = var.cadvisor_external_port
  }

  # Montajes necesarios para que vea los contenedores del host
  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
    read_only      = false
  }

  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker"
    container_path = "/var/lib/docker"
    read_only      = true
  }
}

resource "docker_container" "loki" {
  name  = var.loki_container_name
  image = var.loki_image

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = var.loki_internal_port
    external = var.loki_external_port
  }

  volumes {
    volume_name    = docker_volume.loki_data.name
    container_path = "/loki"
  }
}

resource "docker_container" "promtail" {
  name  = var.promtail_container_name
  image = var.promtail_image

  networks_advanced {
    name = var.network_name
  }

  volumes {
    host_path      = abspath(local_file.promtail_config.filename)
    container_path = "/etc/promtail/config.yml"
    read_only      = true
  }
  # Logs de Docker del host
  volumes {
    host_path      = "/var/lib/docker/containers"
    container_path = "/var/lib/docker/containers"
    read_only      = true
  }

  command = [
    "-config.file=/etc/promtail/config.yml"
  ]
}

#Contenedor Alertmanager
resource "docker_container" "alertmanager" {
  count = var.alerting_enabled ? 1 : 0

  name  = var.alertmanager_container_name
  image = var.alertmanager_image

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = var.alertmanager_internal_port
    external = var.alertmanager_external_port
  }

  volumes {
    host_path      = abspath("${path.module}/alertmanager.yml")
    container_path = "/etc/alertmanager/alertmanager.yml"
    read_only      = true
  }
}