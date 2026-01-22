output "container_names" {
  description = "Lista de nombres de los contenedores web"
  value       = [for c in docker_container.web_container : c.name]
}