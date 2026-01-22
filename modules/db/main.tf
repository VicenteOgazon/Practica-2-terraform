terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

resource "docker_image" "db" {
  name = var.image
}

resource "docker_container" "mysql" {
  name  = var.container_name
  image = docker_image.db.image_id

  env = [
    "MYSQL_HOST=${var.container_name}",
    "MYSQL_ROOT_PASSWORD=${var.db_root_password}",
    "MYSQL_DATABASE=${var.db_name}",
    "MYSQL_USER=${var.db_user}",
    "MYSQL_PASSWORD=${var.db_password}"
  ]

  healthcheck {
      test = ["CMD", "mysqladmin", "ping", "-h", "localhost", "-p${var.db_root_password}"]
      interval = "10s"
      timeout = "5s"
      retries = 3
      start_period = "15s"
  }

  volumes {
    volume_name = docker_volume.db_data.name
    container_path = "/var/lib/mysql"
  }

  volumes {
    host_path      = var.host_path
    container_path = "/docker-entrypoint-initdb.d/init.sql"
  }

  networks_advanced {
    name = var.network_name
  }
}

resource "docker_volume" "db_data" {
  name = var.volume_name
}