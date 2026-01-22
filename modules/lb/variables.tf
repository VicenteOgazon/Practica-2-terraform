variable "image" {
  type = string
}

variable "container_name" {
  type = string
}

variable "listen_port" {
  type = number
}

variable "network_name" {
  type = string
}

variable "backends" {
  type = list(string)
}

variable "backend_port" {
  type = number
  default = 5000
}
