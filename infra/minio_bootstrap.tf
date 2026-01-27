locals {
  minio_bucket = var.environment == "production" ? "static-prod" : "static-dev"
}

# Esperar a que MinIO esté listo (esto se ejecuta en apply, no en plan)
resource "null_resource" "wait_for_minio" {
  depends_on = [module.storage]

  triggers = {
    minio_port = tostring(var.minio_api_external_port)
    minio_name = var.minio_container_name
  }

  provisioner "local-exec" {
    command = <<EOT
set -e
for i in $(seq 1 60); do
  if curl -sf "http://localhost:${var.minio_api_external_port}/minio/health/ready" >/dev/null; then
    echo "MinIO ready"
    exit 0
  fi
  sleep 1
done
echo "MinIO no está listo en http://localhost:${var.minio_api_external_port}" >&2
exit 1
EOT
  }
}

resource "null_resource" "minio_bootstrap" {
  depends_on = [null_resource.wait_for_minio]

  triggers = {
    bucket  = local.minio_bucket
    port    = tostring(var.minio_api_external_port)
    img_md5 = filemd5(abspath(var.minio_background_image_path))
  }

  provisioner "local-exec" {
  command = <<EOT
  set -e

  IMG_PATH="$(realpath "${var.minio_background_image_path}")"
  BUCKET="${local.minio_bucket}"
  PORT="${var.minio_api_external_port}"

  MC_HOST="http://${var.minio_access_key}:${var.minio_secret_key}@localhost:$PORT"

  sudo docker run --rm --network host \
    -e MC_HOST_minio="$MC_HOST" \
    minio/mc mb --ignore-existing "minio/$BUCKET"

  sudo docker run --rm --network host \
    -e MC_HOST_minio="$MC_HOST" \
    minio/mc anonymous set download "minio/$BUCKET"

  sudo docker run --rm --network host \
    -e MC_HOST_minio="$MC_HOST" \
    -v "$IMG_PATH:/tmp/fondo.png:ro" \
    minio/mc cp --attr "Content-Type=image/png" /tmp/fondo.png "minio/$BUCKET/fondo.png"

  sudo docker run --rm --network host \
    -e MC_HOST_minio="$MC_HOST" \
    minio/mc ls "minio/$BUCKET"
  EOT
  }
}