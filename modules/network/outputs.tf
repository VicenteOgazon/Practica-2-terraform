output "network_name" {
  description = "Nombre de la red Docker creada"
  value       = docker_network.network.name
}
