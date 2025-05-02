// Salida de la IP pública de la instancia EC2
output "ec2_public_ip" {
  // Value devuelve la IP pública provisionada para aws_instance.app
  value = aws_eip.app.public_ip
}

// Salida del nombre de dominio completo (FQDN) del servidor PostgreSQL en Azure
output "postgres_fqdn" {
  // Value devuelve el FQDN generado para azurerm_postgresql_server.db
  value = azurerm_postgresql_flexible_server.db_flex.fqdn
}