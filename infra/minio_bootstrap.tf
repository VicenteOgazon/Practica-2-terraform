locals {
  minio_bucket = var.environment == "production" ? "static-prod" : "static-dev"

  background_object_name = "fondo.png"
  background_source_path = abspath(var.minio_background_image_path)
}

# Provider MinIO apuntando al endpoint del MinIO DEL HOST (puerto externo del entorno)
provider "minio" {
  minio_server   = "localhost:${var.minio_api_external_port}"
  minio_user     = var.minio_access_key
  minio_password = var.minio_secret_key
  minio_region   = "us-east-1"
  minio_ssl      = false
}

# Espera simple: que MinIO responda "ready" antes de crear buckets/objetos.
# Evita que el primer apply falle por timing.
resource "null_resource" "wait_for_minio" {
  depends_on = [module.storage]

  triggers = {
    minio_port = tostring(var.minio_api_external_port)
    minio_name = var.minio_container_name
  }

  provisioner "local-exec" {
    command = <<EOT
set -e
for i in $(seq 1 40); do
  if curl -sf "http://localhost:${var.minio_api_external_port}/minio/health/ready" >/dev/null; then
    exit 0
  fi
  sleep 1
done
echo "MinIO no está listo en http://localhost:${var.minio_api_external_port}" >&2
exit 1
EOT
  }
}

resource "minio_s3_bucket" "static_bucket" {
  depends_on = [null_resource.wait_for_minio]

  bucket        = local.minio_bucket
  acl           = "private"
  force_destroy = true
}

resource "minio_s3_object" "background" {
  depends_on   = [minio_s3_bucket_policy.static_public_read]

  bucket_name  = minio_s3_bucket.static_bucket.bucket
  object_name  = "fondo.png"
  source       = abspath(var.minio_background_image_path)
  content_type = "image/png"

  # Puedes dejarlo o quitarlo; la policy es lo que realmente garantiza acceso público
  acl = "public-read"
}

resource "minio_s3_bucket_policy" "static_public_read" {
  depends_on = [minio_s3_bucket.static_bucket]

  bucket = minio_s3_bucket.static_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadObjects",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = ["arn:aws:s3:::${minio_s3_bucket.static_bucket.bucket}/*"]
      }
    ]
  })
}