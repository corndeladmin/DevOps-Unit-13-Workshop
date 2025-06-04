resource "azurerm_service_plan" "finance_package" {
  name                = "${var.prefix}-finance-package-asp"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "finance_package" {
  name                = "${var.prefix}-finance-package-app"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.finance_package.id

  site_config {
    application_stack {
      docker_image_name   = "corndeldevopscourse/m13-finance-package"
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = {
    "TIMEZONE_ID"                    = "Europe/London"
    "ORDER_SERVICE_URL"              = "https://${local.order_processing_app_service_name}.azurewebsites.net"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "ENABLE_ORYX_BUILD"              = "true"
    "DISABLE_SEED"                   = "true"
  }
}