variable "image" {
  type = string
}

variable "container_name" {
  type = string
}

variable "internal_port" {
  type    = number
  default = 6379
}

variable "external_port" {
  type    = number
  default = null
}

variable "network_name" {
  type = string
}