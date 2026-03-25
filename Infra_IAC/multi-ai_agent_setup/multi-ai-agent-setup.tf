terraform {
  required_providers { azurerm = { source = "hashicorp/azurerm" version = "~> 3.0" } }
}

provider "azurerm" { features {} }

resource "azurerm_resource_group" "mas_rg" {
  name     = "multi-agent-system-rg"
  location = "East US"
}

# OpenAI & Model
resource "azurerm_cognitive_account" "openai" {
  name = "mas-openai-service" ; location = azurerm_resource_group.mas_rg.location
  resource_group_name = azurerm_resource_group.mas_rg.name ; kind = "OpenAI" ; sku_name = "S0"
}

resource "azurerm_cognitive_deployment" "gpt4" {
  name = "gpt-4o" ; cognitive_account_id = azurerm_cognitive_account.openai.id
  model { format = "OpenAI" ; name = "gpt-4o" ; version = "2024-05-13" }
  sku { name = "Standard" ; capacity = 10 }
}

# Cosmos DB for Logs
resource "azurerm_cosmosdb_account" "cosmos" {
  name = "mas-cosmos-db-account" ; location = azurerm_resource_group.mas_rg.location
  resource_group_name = azurerm_resource_group.mas_rg.name ; offer_type = "Standard" ; kind = "GlobalDocumentDB"
  consistency_policy { consistency_level = "Session" }
  geo_location { location = azurerm_resource_group.mas_rg.location ; failover_priority = 0 }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name = "ChatDB" ; resource_group_name = azurerm_resource_group.mas_rg.name ; account_name = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "logs" {
  name = "Logs" ; resource_group_name = azurerm_resource_group.mas_rg.name ; account_name = azurerm_cosmosdb_account.cosmos.name
  database_name = azurerm_cosmosdb_sql_database.db.name ; partition_key_path = "/id"
}

# Function App
resource "azurerm_storage_account" "st" {
  name = "masfuncstorage" ; resource_group_name = azurerm_resource_group.mas_rg.name
  location = azurerm_resource_group.mas_rg.location ; account_tier = "Standard" ; account_replication_type = "LRS"
}

resource "azurerm_service_plan" "asp" {
  name = "mas-plan" ; resource_group_name = azurerm_resource_group.mas_rg.name
  location = azurerm_resource_group.mas_rg.location ; os_type = "Linux" ; sku_name = "Y1"
}

resource "azurerm_linux_function_app" "mas_func" {
  name = "mas-agent-orchestrator" ; resource_group_name = azurerm_resource_group.mas_rg.name
  location = azurerm_resource_group.mas_rg.location ; service_plan_id = azurerm_service_plan.asp.id
  storage_account_name = azurerm_storage_account.st.name ; storage_account_access_key = azurerm_storage_account.st.primary_access_key
  site_config { application_stack { python_version = "3.10" } }
  app_settings = {
    "AzureWebJobsFeatureFlags" = "EnableWorkerIndexing"
    "AZURE_OPENAI_ENDPOINT"    = azurerm_cognitive_account.openai.endpoint
    "AZURE_OPENAI_KEY"         = azurerm_cognitive_account.openai.primary_access_key
    "COSMOS_DB_CONNECTION"     = azurerm_cosmosdb_account.cosmos.primary_sql_connection_string
    "FUNCTIONS_WORKER_RUNTIME" = "python"
  }
}
