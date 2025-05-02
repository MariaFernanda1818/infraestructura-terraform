
// --------------------------------------------------
// Declaración de Grupo de Recursos y Servidor PostgreSQL
// --------------------------------------------------

// Crea un grupo de recursos en Azure donde se ubicarán todos los recursos relacionados
resource "azurerm_resource_group" "rg" {
  // Nombre único para el recurso
  name     = "aplicaciones-mias"
  // Región geográfica donde se creará el grupo
  location = "centralus"
}

resource "azurerm_postgresql_flexible_server" "db_flex" {
  name                         = "pg-flex-prueba-tecnica-backend"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location

  sku_name                     = "B_Standard_B1ms"
  version                      = "13"
  administrator_login          = "adminpg"
  administrator_password       = "ComplexP@ssw0rd!"
  storage_mb                   = 32768
  backup_retention_days        = 7

  public_network_access_enabled = true  # ← aquí, a nivel raíz
  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone,
    ]
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all_ips" {
  name                = "allow-all"
  server_id           = azurerm_postgresql_flexible_server.db_flex.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}
