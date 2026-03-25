terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Version 4.0+ is recommended for latest OpenAI & Function App features
      version = "~> 4.0"
    }
    # ADD THIS: The Time Provider
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    # Required for Cognitive Services (OpenAI)
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}
provider "time" {}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-openai-function-app"
  location = "australiacentral" #"East US"
}



# 2. Storage Account (Required for Function App)
resource "azurerm_storage_account" "storage" {
  name                     = "pythnhhppanopenai001"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}




resource "time_sleep" "wait_for_storage" {
  depends_on = [azurerm_storage_account.storage]
  create_duration = "30s"
}



# 3. Service Plan (Linux)
resource "azurerm_service_plan" "plan" {
  name                = "asp-openai-function"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" # "Y1" # Consumption plan
}


# 4. Linux Function App
resource "azurerm_linux_function_app" "func" {
  name                = "func-openai-logic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  # Use the sleep resource to ensure the SA is ready
  depends_on = [time_sleep.wait_for_storage]

  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  service_plan_id            = azurerm_service_plan.plan.id
  
  # Ensure the extension version is pinned to ~4
  functions_extension_version = "~4"

  site_config {
    application_stack {
      python_version = "3.11" # Adjust based on your code
    }
  }


  app_settings = {
  # This setting is required for Linux Python functions
  "FUNCTIONS_WORKER_RUNTIME" = "python"
   # "OPENAI_API_KEY"      = azurerm_cognitive_account.openai.primary_access_key
   # "OPENAI_ENDPOINT"     = azurerm_cognitive_account.openai.endpoint
   # "GPT_MODEL_NAME"      = "gpt-53"
   # "EMBEDDING_MODEL_NAME" = "text-embedding-ada-32"
  }
}

#################### Deploying list of Python Based functions - into Azure linux function app  #####################
locals {
  # Define the specific attributes for each timer function
  timer_configs = {
    "timer_total_tokens"      = { metric = "ProcessedTokens" },
    "timer_prompt_tokens"     = { metric = "ProcessedPromptTokens" },
    "timer_completion_tokens" = { metric = "GeneratedCompletionTokens" },
    "timer_total_requests"    = { metric = "TotalCalls" }
  }
}

resource "azurerm_function_app_function" "timer_functions" {
  for_each        = local.timer_configs
  name            = each.key
  function_app_id = azurerm_linux_function_app.func.id
  language        = "Python"

  # This replaces the @app.timer_trigger decorator logic
  config_json = jsonencode({
    "bindings" = [
      {
        "name"     = "myTimer"
        "type"     = "timerTrigger"
        "direction" = "in"
        "schedule"  = "0 0 * * * *" # Every hour
      }
    ]
  })

  # Optional: You can provide the raw python code here if using 'In-Portal' editing,
  # but Zip Deploy is recommended for production.
  file {
    name    = "__init__.py"
    content = <<-EOT
      import logging
      import azure.functions as func
      # Assuming get_openai_metric is available in your shared logic
      from shared_logic import get_openai_metric 

      def main(myTimer: func.TimerRequest) -> None:
          metric_name = "${each.value.metric}"
          val = get_openai_metric(metric_name)
          logging.info(f"Monitor: {metric_name} is {val}")
    EOT
  }
}

#####
























## 5. Azure OpenAI Account
#resource "azurerm_cognitive_account" "openai" {
#  name                = "openai-service-instance"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name
#  kind                = "OpenAI"
#  sku_name            = "S0"
#  custom_subdomain_name = "openai-service-instance-unique" # Must be globally unique
#}

## 6. GPT-5.3 Model Deployment
#resource "azurerm_cognitive_deployment" "gpt53" {
#  name                 = "gpt-53"
#  cognitive_account_id = azurerm_cognitive_account.openai.id
#  model {
#    format  = "OpenAI"
#    name    = "gpt-5.3-chat" # Adjust to exact provider string if different
#    version = "2026-03-03"   # Latest preview version
#  }
#  sku {
#    name = "GlobalStandard"
#    capacity = 1
#  }
#}

## 7. Text-Embedding-Ada-3.2 Model Deployment
#resource "azurerm_cognitive_deployment" "embeddings" {
#  name                 = "text-embedding-ada-32"
#  cognitive_account_id = azurerm_cognitive_account.openai.id
#  model {
#    format  = "OpenAI"
#    name    = "text-embedding-ada-3.2"
#    version = "1"
#  }
#  sku {
#    name = "GlobalStandard"
#    capacity = 1
#  }
#}
