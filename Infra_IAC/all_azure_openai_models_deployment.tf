#Azure openai with Diagnostic - logs_events_metrics_traces_transfer_to_SA_Eventhub_Log_analytics_workspace

# 1. Resource Group
resource "azurerm_resource_group" "rg-openai-full-stack-python" {
  name     = "rg-openai-full-stack-python"
  #name      = "rg-openai-function-app"
  location = "East US"
}

# 2. Azure OpenAI Service (Account)
resource "azurerm_cognitive_account" "openai" {
  name                = "openai-service-full-001-python"
  location            = azurerm_resource_group.rg-openai-full-stack-python.location
  resource_group_name = azurerm_resource_group.rg-openai-full-stack-python.name
  kind                = "OpenAI"
  sku_name            = "S0"
}

# 3. Model Deployment (e.g., GPT-4o)
resource "azurerm_cognitive_deployment" "gpt4" {
  name                 = "gpt-4o-deployment-python"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format  = "OpenAI"
    name    = "gpt-4o" # Ensure this model is available in your chosen region
    version = "2024-05-13"
  }
  sku {
    name     = "Standard"
    capacity = 10 # Tokens Per Minute (TPM) in thousands
  }
}

#3.1 Model Deployment (e.g text-embedding-ada-3.2)
resource "azurerm_cognitive_deployment" "embedding_ada" {
  name                 = "text-embedding-ada-002-deployment-python"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }
  sku {
    name     = "Standard"
    capacity = 100
  }
}
#3.1.1
#resource "azurerm_cognitive_deployment" "embedding_v3" {
#  name                 = "text-embedding-3-large-deployment-python"
#  cognitive_account_id = azurerm_cognitive_account.openai.id
#  model {
#    format  = "OpenAI"
#    name    = "text-embedding-3-large"
#    version = "1" # Check regional availability for version 1
#  }
#  sku {
#    name     = "Standard"
#    capacity = 100 # TPM in thousands
#  }
#}


#3.2 Model Deployment (e.g dalle3 )

#resource "azurerm_cognitive_deployment" "dalle3" {
#  name                 = "dall-e-3-deployment-python"
#  cognitive_account_id = azurerm_cognitive_account.openai.id
#  model {
#    format  = "OpenAI"
#    name    = "dall-e-3"
#    version = "1" #"4.0" #"3.0"
#  }
#  sku {
#    name     = "Standard"
#    capacity = 1 # Dalle-3 uses capacity units differently
#  }
#}


#3.3 Model Deployment(e.g whisper )
#resource "azurerm_cognitive_deployment" "whisper" {
#  name                 = "whisper-deployment-python"
#  cognitive_account_id = azurerm_cognitive_account.openai.id
#  model {
#    format  = "OpenAI"
#    name    = "whisper"
#    version = "001"
#  }
#  sku {
#    name     = "ProvisionedManaged" #"Standard"
#    capacity = 1
#  }
#}


################### whisper model deployment to eastus2 location ########################
# 1. Resource Group in East US 2
resource "azurerm_resource_group" "rg-whisper" {
  name     = "rg-openai-whisper-eastus2"
  location = "eastus2" # Whisper is available in East US 2
}

# 2. Azure OpenAI Account
resource "azurerm_cognitive_account" "openai-whisper" {
  name                = "openai-whisper-service"
  location            = azurerm_resource_group.rg-whisper.location
  resource_group_name = azurerm_resource_group.rg-whisper.name
  kind                = "OpenAI"
  sku_name            = "S0"
}

# 3. Whisper Model Deployment
resource "azurerm_cognitive_deployment" "whisper" {
  name                 = "whisper-deployment"
  cognitive_account_id = azurerm_cognitive_account.openai-whisper.id

  model {
    format  = "OpenAI"
    name    = "whisper"
    version = "001" # Standard version for GA Whisper
  }

  sku {
    name     = "Standard" # ProvisionedManaged is not supported for Whisper [Error Context]
    capacity = 1          # Standard capacity for Whisper is typically low
  }
}


# 3. TTS Model Deployment (Standard Quality)
#resource "azurerm_cognitive_deployment" "tts" {
#  name                 = "tts-deployment"
#  cognitive_account_id = azurerm_cognitive_account.openai-whisper.id

#  model {
#    format  = "OpenAI"
#    name    = "tts-1" # Use "tts-1-hd" for high-definition quality
#    version = "1"
#  }

#  sku {
#    name     = "Standard"
#    capacity = 1
#  }
#}


######################################


##################### Deploying Audio Models ############################
# GPT-Audio
# GPT-AUDIO-1.5
# GPT-AUDIO-MINI 

# 1. GPT-4o Audio Preview (Standard Audio)
#resource "azurerm_cognitive_deployment" "gpt_audio" {
#  name                 = "gpt-audio-deployment"
#  cognitive_account_id = azurerm_cognitive_account.openai-whisper.id

#  model {
#    format  = "OpenAI"
#    name    = "gpt-4o-audio-preview"
#    version = "2024-12-17" 
#  }

#  sku {
#    name = "GlobalStandard" # Recommended for Audio Preview models
#    capacity = 100
#  }
#}

# 2. GPT-4o Mini Audio Preview
resource "azurerm_cognitive_deployment" "gpt_audio_mini" {
  name                 = "gpt-audio-mini-deployment"
  cognitive_account_id = azurerm_cognitive_account.openai-whisper.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini-audio-preview"
    version = "2024-12-17"
  }

  sku {
    name = "GlobalStandard"
    capacity = 100
  }
}

# 3. GPT-Audio-1.5 (Latest Version)
#resource "azurerm_cognitive_deployment" "gpt_audio_15" {
#  name                 = "gpt-audio-1-5-deployment"
#  cognitive_account_id = azurerm_cognitive_account.openai-whisper.id

#  model {
#    format  = "OpenAI"
#    name    = "gpt-audio-1.5"
#    version = "2026-02-23" # Released February 2026
#  }

#  sku {
#    name = "Standard"
#    capacity = 1
#  }
#}



#########################################################################


# 4. Destination: Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-openai-monitoring-python"
  location            = azurerm_resource_group.rg-openai-full-stack-python.location
  resource_group_name = azurerm_resource_group.rg-openai-full-stack-python.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# 5. Destination: Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = "saopenaidiag001python"
  resource_group_name      = azurerm_resource_group.rg-openai-full-stack-python.name
  location                 = azurerm_resource_group.rg-openai-full-stack-python.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 6. Destination: Event Hub
resource "azurerm_eventhub_namespace" "ehn" {
  name                = "evh-ns-openai-stream-python"
  location            = azurerm_resource_group.rg-openai-full-stack-python.location
  resource_group_name = azurerm_resource_group.rg-openai-full-stack-python.name
  sku                 = "Standard"
}

resource "azurerm_eventhub" "eh" {
  name                = "openai-telemetry-hub-python"
  namespace_name      = azurerm_eventhub_namespace.ehn.name
  resource_group_name = azurerm_resource_group.rg-openai-full-stack-python.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "rule" {
  name                = "diag-transfer-rule-python"
  namespace_name      = azurerm_eventhub_namespace.ehn.name
  resource_group_name = azurerm_resource_group.rg-openai-full-stack-python.name
  send                = true
}

# 7. Diagnostic Setting (The Bridge)
resource "azurerm_monitor_diagnostic_setting" "openai_diag" {
  name                       = "openai-full-telemetry-transfer-python"
  target_resource_id         = azurerm_cognitive_account.openai.id
  
  log_analytics_workspace_id      = azurerm_log_analytics_workspace.law.id
  storage_account_id              = azurerm_storage_account.sa.id
  eventhub_name                   = azurerm_eventhub.eh.name
  eventhub_authorization_rule_id  = azurerm_eventhub_namespace_authorization_rule.rule.id

  # Captures Audit, RequestResponse, and Trace
  enabled_log {
    category_group = "allLogs"
  }

  # Captures all performance metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [
    azurerm_cognitive_deployment.gpt4,
    #azurerm_cognitive_deployment.dalle3,
    azurerm_cognitive_deployment.whisper,
    azurerm_cognitive_deployment.embedding_ada, # or embedding_ada
    #azurerm_cognitive_deployment.embedding_v3 # or embedding_ada
  
    
    ]

}
