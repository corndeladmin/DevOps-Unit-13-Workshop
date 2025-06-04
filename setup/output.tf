output "db_access_details" {
  value = {
    order_processing_website = "https://${azurerm_linux_web_app.image_processing.default_hostname}"
    database_server     = azurerm_mssql_server.sql.fully_qualified_domain_name
    database_name       = azurerm_mssql_database.sql.name
    db_username            = "dbadmin"
    db_password            = nonsensitive(random_password.server_password.result)
  }
}
