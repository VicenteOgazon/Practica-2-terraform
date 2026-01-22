variable "image" {
  description = "Imagen Docker para la base de datos"
  type        = string
}

variable "container_name" {
  description = "Nombre del contenedor de base de datos"
  type        = string
}

variable "internal_port" {
  type        = number
  description = "Puerto interno del contenedor de base de datos"
}

variable "app_env" {
  type        = string
  description = "Entorno de la aplicación (development, production, etc.)"
}

variable "db_container_name" {
  type        = string
  description = "Nombre del contenedor de la base de datos"
}

variable "db_name" {
  type        = string
  description = "Nombre de la base de datos"
}

variable "db_user" {
  type        = string
  description = "Usuario de la base de datos"
}

variable "db_password" {
  type        = string
  description = "Password del usuario de la base de datos"
  sensitive   = true
}

variable "db_root_pass" {
  type        = string
  description = "Password de root de la base de datos (MySQL, por ejemplo)"
  sensitive   = true
}

variable "network_name" {
  type        = string
  description = "Nombre de la red Docker a la que se conecta la DB"
}

variable "cache_container_name" {
  type        = string
  description = "Nombre del contenedor de caché"
}

variable "replicas" {
  description = "Número de réplicas del contenedor web"
  type        = number
}