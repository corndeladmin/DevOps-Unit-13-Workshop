resource "azurerm_service_plan" "order_processing" {
  name                = "${var.prefix}-order-processing-asp"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"
}

locals {
  order_processing_app_service_name = "${var.prefix}-order-processing-app"
}

resource "azurerm_linux_web_app" "image_processing" {
  name                = local.order_processing_app_service_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.order_processing.id

  lifecycle {
    ignore_changes = [app_settings]
  }

  site_config {
    application_stack {
      docker_image_name   = "corndeldevopscourse/m14-image-processing-app:latest"
      docker_registry_url = "https://index.docker.io"
    }
    always_on = true
  }

  app_settings = {
    "SCHEDULED_JOB_INTERVAL_SECONDS" = "15"
    "SCHEDULED_JOB_MAX_INSTANCES"    = "2"
    "DB_SERVER_NAME"                 = azurerm_mssql_server.sql.fully_qualified_domain_name
    "DATABASE_NAME"                  = azurerm_mssql_database.sql.name
    "DATABASE_USER"                  = "dbadmin"
    "DATABASE_PASSWORD"              = random_password.server_password.result
    "FINANCE_PACKAGE_URL"            = "https://${azurerm_linux_web_app.finance_package.default_hostname}"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "ENABLE_ORYX_BUILD"              = "true"
    "SCHEDULED_JOB_ENABLED"          = "true"
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 2
        retention_in_mb   = 35
      }
    }
  }
}