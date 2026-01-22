terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

resource "docker_volume" "minio_data" {
  name = "${var.minio_container_name}_data"
}

resource "docker_container" "minio" {
  name  = var.minio_container_name
  image = var.minio_image

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = var.minio_api_internal_port
    external = var.minio_api_external_port
  }

  ports {
    internal = var.minio_console_internal_port
    external = var.minio_console_external_port
  }

  env = [
    "MINIO_ROOT_USER=${var.minio_access_key}",
    "MINIO_ROOT_PASSWORD=${var.minio_secret_key}"
  ]

  volumes {
    volume_name    = docker_volume.minio_data.name
    container_path = "/data"
  }

  command = [
    "server",
    "/data",
    "--console-address",
    ":${var.minio_console_internal_port}"
  ]
}