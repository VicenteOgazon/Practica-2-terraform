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


resource "docker_image" "lb" {
  name = var.image
}

locals {
  backends_text = join("\n", [for b in var.backends : "${b}:${var.backend_port}"])

  nginx_conf = templatefile("${path.module}/nginx.conf.tpl", {
    listen_port   = 80
    backends      = var.backends
    backend_port  = var.backend_port
    backends_text = local.backends_text
  })
}


#Empleamos el resource local para crear en mi máquina un fichero con nginx_conf
resource "local_file" "nginx_conf" {
  content  = local.nginx_conf
  filename = abspath("${path.module}/${var.container_name}_replicas.conf")
}

resource "docker_container" "lb" {
  name  = var.container_name
  image = docker_image.lb.image_id

  ports {
    internal = 80
    external = var.listen_port
  }

  healthcheck {
      test     = ["CMD", "curl", "-f", "http://localhost/lb-health"]
      interval = "10s"
      timeout = "5s"
      retries = 3
      start_period = "15s"
  }

  networks_advanced {
    name = var.network_name
  }

#Montamos el fichero con los contenedores web disponibles en la configuración de Nginx para que los cargue al arrancar
  mounts {
    source = local_file.nginx_conf.filename
    target = "/etc/nginx/conf.d/default.conf"
    type   = "bind"
  }
}