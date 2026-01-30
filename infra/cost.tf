locals {
  hours_per_month = 730 # aproximación (30,4 días * 24h)

  # Precios aproximados (EC2 On-Demand Linux) en eu-south-2
  ec2_price_usd_per_hour = {
    "t3.micro" = 0.0114 # coste por hora
    "t3.small" = 0.0228 # coste por hora
  }

    # Cantidades de instancias
  count_web_instances    = var.web_replicas
  count_lb_instances     = 1
  count_minio_instances  = 1
  count_db_instances     = 1
  count_cache_instances  = var.enable_cache ? 1 : 0
  count_monitoring_micro = var.environment == "production" ? 0 : 1
  count_monitoring_small = var.environment == "production" ? 1 : 0

  # Costes por tipo de infraestructura ($/mes)
  cost_web        = local.count_web_instances * local.ec2_price_usd_per_hour["t3.micro"] * local.hours_per_month
  cost_lb         = local.count_lb_instances  * local.ec2_price_usd_per_hour["t3.micro"] * local.hours_per_month
  cost_minio      = local.count_minio_instances * local.ec2_price_usd_per_hour["t3.micro"] * local.hours_per_month
  cost_db         = local.count_db_instances  * local.ec2_price_usd_per_hour["t3.small"] * local.hours_per_month
  cost_cache      = local.count_cache_instances * local.ec2_price_usd_per_hour["t3.micro"] * local.hours_per_month
  cost_monitoring = (
    local.count_monitoring_micro * local.ec2_price_usd_per_hour["t3.micro"] * local.hours_per_month
    + local.count_monitoring_small * local.ec2_price_usd_per_hour["t3.small"] * local.hours_per_month
  )

  cost_total = (
    local.cost_web
    + local.cost_lb
    + local.cost_db
    + local.cost_cache
    + local.cost_minio
    + local.cost_monitoring
  )

  # Formato con 2 decimales
  cost_web_str        = format("%.2f", local.cost_web)
  cost_lb_str         = format("%.2f", local.cost_lb)
  cost_db_str         = format("%.2f", local.cost_db)
  cost_cache_str      = format("%.2f", local.cost_cache)
  cost_minio_str      = format("%.2f", local.cost_minio)
  cost_monitoring_str = format("%.2f", local.cost_monitoring)
  cost_total_str      = format("%.2f", local.cost_total)
}

output "cost_monthly_summary" {
  value = <<EOT
Estimación mensual en AWS EC2 On-Demand eu-south-2

Suposiciones:
- Web: 1 x t3.micro por réplica
- Base de datos: 1 x t3.small
- Balanceador (LB): 1 x t3.micro
- MinIO: 1 x t3.micro
- Monitorización: dev = t3.micro, prod = t3.small
- Caché: 1 x t3.micro solo si enable_cache = true
- Se usa 730 horas/mes como aproximación

Desglose ($/mes):
- Web (${local.count_web_instances} x t3.micro): ${local.cost_web_str} $
- Base de datos (1 x t3.small): ${local.cost_db_str} $
- Balanceador (1 x t3.micro): ${local.cost_lb_str} $
- MinIO (1 x t3.micro): ${local.cost_minio_str} $
- Monitorización: ${local.cost_monitoring_str} $
- Caché (${local.count_cache_instances} x t3.micro): ${local.cost_cache_str} $

TOTAL: ${local.cost_total_str} $/mes
EOT
}