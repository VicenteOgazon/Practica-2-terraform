terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }

    minio = {
      source  = "aminueza/minio"
      version = ">= 3.12.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}