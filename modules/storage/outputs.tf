output "bucket_name" {
  value       = local.minio_bucket
  description = "Bucket de estáticos del entorno"
}

output "api_port" {
  value       = var.minio_api_external_port
  description = "Puerto externo API MinIO"
}