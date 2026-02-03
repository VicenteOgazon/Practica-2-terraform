terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
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

module "network" {
  source       = "../modules/network"
  network_name = var.network_name
}

module "mysql" {
  source = "../modules/db"

  image            = var.db_image
  container_name   = var.db_container_name
  db_name          = var.db_name
  db_user          = var.db_user
  db_password      = var.db_password
  db_root_password = var.db_root_password
  host_path        = var.db_init
  volume_name      = var.volume_name
  network_name     = module.network.network_name
}

module "cache" {
  source = "../modules/cache"
  count  = var.enable_cache ? 1 : 0 # count decide si se crea el modulo o no

  image          = var.cache_image
  container_name = var.cache_container_name
  network_name   = module.network.network_name
}


locals {
  effective_cache_name = var.enable_cache ? var.cache_container_name : ""

  prometheus_scrape_targets = [
    for i in range(var.web_replicas) : "${var.web_container_name}-${i}:${var.web_internal_port}"
  ]
}

module "web" {
  source = "../modules/web"

  replicas       = var.web_replicas
  image          = var.app_image
  container_name = var.web_container_name
  internal_port  = var.web_internal_port
  app_env        = var.environment

  db_container_name = var.db_container_name
  db_root_pass      = var.db_root_password
  db_name           = var.db_name
  db_user           = var.db_user
  db_password       = var.db_password

  cache_container_name = local.effective_cache_name

  network_name = module.network.network_name
}

module "lb" {
  source = "../modules/lb"

  image          = var.lb_image
  container_name = var.lb_container_name
  listen_port    = var.lb_listen_port
  network_name   = module.network.network_name

  backends     = module.web.container_names
  backend_port = var.web_internal_port
}

module "monitoring" {
  source = "../modules/monitoring"

  network_name = module.network.network_name

  prometheus_image          = var.prometheus_image
  prometheus_container_name = var.prometheus_container_name
  prometheus_internal_port  = var.prometheus_internal_port
  prometheus_external_port  = var.prometheus_external_port
  prometheus_scrape_targets = local.prometheus_scrape_targets

  grafana_image          = var.grafana_image
  grafana_container_name = var.grafana_container_name
  grafana_internal_port  = var.grafana_internal_port
  grafana_external_port  = var.grafana_external_port
  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password

  cadvisor_image          = var.cadvisor_image
  cadvisor_container_name = var.cadvisor_container_name
  cadvisor_internal_port  = var.cadvisor_internal_port
  cadvisor_external_port  = var.cadvisor_external_port

  loki_image          = var.loki_image
  loki_container_name = var.loki_container_name
  loki_internal_port  = var.loki_internal_port
  loki_external_port  = var.loki_external_port

  promtail_image          = var.promtail_image
  promtail_container_name = var.promtail_container_name

  alerting_enabled         = var.alerting_enabled
  alertmanager_image       = var.alertmanager_image
  alertmanager_container_name = var.alertmanager_container_name
  alertmanager_internal_port   = var.alertmanager_internal_port
  alertmanager_external_port   = var.alertmanager_external_port
}

module "storage" {
  source = "../modules/storage"

  minio_image                 = var.minio_image
  minio_container_name        = var.minio_container_name
  minio_access_key            = var.minio_access_key
  minio_secret_key            = var.minio_secret_key
  minio_api_internal_port     = var.minio_api_internal_port
  minio_api_external_port     = var.minio_api_external_port
  minio_console_internal_port = var.minio_console_internal_port
  minio_console_external_port = var.minio_console_external_port
  network_name                = module.network.network_name

  environment                 = var.environment
  minio_background_image_path = var.minio_background_image_path
}