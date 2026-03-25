# --- Infrastructure ---
resource "azurerm_resource_group" "rg" {
  name     = "func-demo-rg"
  location = "East US"
}

resource "azurerm_storage_account" "st" {
  name                     = "stfuncappdemo001"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "asp" {
  name                = "asp-linux-python"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "app" {
  name                       = "linux-python-app"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key

  site_config {
    application_stack { python_version = "3.11" }
  }

  app_settings = {
    "AzureWebJobsStorage"    = azurerm_storage_account.st.primary_connection_string
    "SERVICE_BUS_CONNECTION" = "<connection-string>"
    "EVENT_HUB_CONNECTION"   = "<connection-string>"
    "COSMOS_DB_CONNECTION"   = "<connection-string>"
    "SQL_DB_CONNECTION"      = "<connection-string>"
  }
}

# --- Function Definitions (Triggers) ---
resource "azurerm_linux_function_app_function" "triggers" {
  for_each = {
    "HttpTrigger"     = { type = "httpTrigger", direction = "in", name = "req", authLevel = "anonymous", methods = ["get", "post"] }
    "QueueTrigger"    = { type = "queueTrigger", direction = "in", name = "msg", queueName = "input-q", connection = "AzureWebJobsStorage" }
    "SBQueueTrigger"  = { type = "serviceBusTrigger", direction = "in", name = "msg", queueName = "sb-q", connection = "SERVICE_BUS_CONNECTION" }
    "SBTopicTrigger"  = { type = "serviceBusTrigger", direction = "in", name = "msg", topicName = "sb-t", subscriptionName = "sub1", connection = "SERVICE_BUS_CONNECTION" }
    "BlobTrigger"     = { type = "blobTrigger", direction = "in", name = "myblob", path = "samples/{name}", connection = "AzureWebJobsStorage" }
    "EventGridTrig"   = { type = "eventGridTrigger", direction = "in", name = "event" }
    "EventHubTrig"    = { type = "eventHubTrigger", direction = "in", name = "hub", eventHubName = "ehub", connection = "EVENT_HUB_CONNECTION" }
    "CosmosTrig"      = { type = "cosmosDBTrigger", direction = "in", name = "docs", databaseName = "db", containerName = "items", connection = "COSMOS_DB_CONNECTION", leaseContainerName = "leases", createLeaseContainerIfNotExists = true }
    "SqlTrig"         = { type = "sqlTrigger", direction = "in", name = "changes", tableName = "dbo.Table", connectionStringSetting = "SQL_DB_CONNECTION" }
    "DurableActivity" = { type = "activityTrigger", direction = "in", name = "name" }
  }

  name            = each.key
  function_app_id = azurerm_linux_function_app.app.id
  language        = "Python"
  config_json     = jsonencode({ "bindings" : [each.value] })
}
