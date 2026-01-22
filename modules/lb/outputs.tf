output "container_name" {
  description = "Nombre del contenedor del load balancer"
  value       = docker_container.lb.name
}

output "url" {
  description = "URL de acceso al servicio balanceado"
  value       = "http://localhost:${var.listen_port}"
}