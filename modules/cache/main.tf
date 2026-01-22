terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

resource "docker_image" "cache" {
  name = var.image
}

resource "docker_container" "cache_container" {
  image   = docker_image.cache.image_id
  name    = var.container_name
  restart = "always"

  dynamic "ports" {
    for_each = var.external_port == null ? [] : [1]
    content {
      internal = var.internal_port
      external = var.external_port
    }
  }

  healthcheck {
    test         = ["CMD", "redis-cli", "ping"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "15s"
  }

  networks_advanced {
    name = var.network_name
  }
}