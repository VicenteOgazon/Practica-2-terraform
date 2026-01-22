terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}


resource "docker_image" "web" {
  name = var.image
}

# Create a container
resource "docker_container" "web_container" {

  count = var.replicas
  image = docker_image.web.image_id
  name  = "${var.container_name}-${count.index}"

  restart = "always"

  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost:${var.internal_port}/health"]
    interval = "10s"
      timeout = "5s"
      retries = 3
      start_period = "15s"
  }

  env = [
    "INSTANCE_NAME=${var.container_name}-${count.index}",
    "APP_ENV=${var.app_env}",
    "APP_PORT=${var.internal_port}",
    "MYSQL_HOST=${var.db_container_name}",
    "MYSQL_ROOT_PASSWORD=${var.db_root_pass}",
    "MYSQL_DATABASE=${var.db_name}",
    "MYSQL_USER=${var.db_user}",
    "MYSQL_PASSWORD=${var.db_password}",
    "REDIS_HOST=${var.cache_container_name}"
  ]

  networks_advanced {
    name = var.network_name
  }
}