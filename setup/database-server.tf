resource "random_password" "server_password" {
  length           = 30
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "_!#"
}

resource "azurerm_mssql_server" "sql" {
  name                         = "${var.prefix}-order-processing-sqlserver"
  resource_group_name          = data.azurerm_resource_group.main.name
  location                     = data.azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "dbadmin"
  administrator_login_password = random_password.server_password.result
}

resource "azurerm_mssql_database" "sql" {
  name           = "${var.prefix}-order-processing-db"
  server_id      = azurerm_mssql_server.sql.id
  max_size_gb    = 2
  sku_name       = "Basic"
  zone_redundant = false
}

resource "azurerm_mssql_firewall_rule" "sql" {
  name      = "${var.prefix}-sql-db-firewall-rule"
  server_id = azurerm_mssql_server.sql.id

  # 0.0.0.0 - 0.0.0.0 means allow all Azure IPs
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
