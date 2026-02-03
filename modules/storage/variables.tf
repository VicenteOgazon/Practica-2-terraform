variable "minio_image" {
  type = string
}

variable "minio_container_name" {
  type = string
}

variable "minio_access_key" {
  type = string
}

variable "minio_secret_key" {
  type = string
}

variable "minio_api_internal_port" {
  type    = number
  default = 9000
}

variable "minio_api_external_port" {
  type = number
}

variable "minio_console_internal_port" {
  type    = number
  default = 9001
}

variable "minio_console_external_port" {
  type = number
}

variable "network_name" {
  type = string
}

variable "environment" {
  type        = string
  description = "Entorno: development/production"
}

variable "minio_background_image_path" {
  type        = string
  description = "Ruta local al fichero fondo.png para subirlo al bucket"
}

