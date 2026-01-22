variable "image" {
  description = "Imagen Docker para la base de datos"
  type        = string
}

variable "container_name" {
  description = "Nombre del contenedor de base de datos"
  type = string
}

variable "db_name" {
  type = string
  description = "Nombre de la base de datos"
}

variable "db_user" {
  type = string
  description = "Usuario de la base de datos"
}

variable "db_password" {
  type = string
  description = "Password del usuario de la base de datos"
  sensitive   = true
}

variable "db_root_password" {
  type = string
  description = "Password de root de la base de datos (MySQL, por ejemplo)"
  sensitive   = true
}

variable "network_name" {
  type = string
  description = "Nombre de la red Docker a la que se conecta la DB"
}

variable "host_path" {
  type = string
  description = "Ruta en el host para el script de inicialización de la base de datos"
}

variable "volume_name" {
  type = string
  description = "Nombre del volumen Docker para persistencia de datos"
}