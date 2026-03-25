# --- 1. PROVIDER & RESOURCE GROUP ---
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "cosmos" {
  name     = "rg-cosmos-full-stack"
  location = "East US"
}

# --- 2. SQL, GREMLIN, & TABLE API (Shared Account) ---
resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-acc-main-apis"
  location            = azurerm_resource_group.cosmos.location
  resource_group_name = azurerm_resource_group.cosmos.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy { consistency_level = "Session" }
  geo_location {
    location          = azurerm_resource_group.cosmos.location
    failover_priority = 0
  }
}

# SQL API Database & Container
resource "azurerm_cosmosdb_sql_database" "sql" {
  name                = "nosql-db"
  resource_group_name = azurerm_resource_group.cosmos.name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_cosmosdb_sql_container" "sql_container" {
  name                = "Items"
  resource_group_name = azurerm_resource_group.cosmos.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.sql.name
  partition_key_path  = "/definition/id"
  throughput          = 400
}

# Gremlin (Graph) API Database & Graph
resource "azurerm_cosmosdb_gremlin_database" "gremlin" {
  name                = "graph-db"
  resource_group_name = azurerm_resource_group.cosmos.name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_cosmosdb_gremlin_graph" "graph" {
  name                = "UserGraph"
  resource_group_name = azurerm_resource_group.cosmos.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_gremlin_database.gremlin.name
  partition_key_path  = "/pk"
  throughput          = 400
}

# Table API
resource "azurerm_cosmosdb_table" "table" {
  name                = "DataTable"
  resource_group_name = azurerm_resource_group.cosmos.name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = 400
}

# --- 3. MONGODB API (Dedicated Account) ---
resource "azurerm_cosmosdb_account" "mongo_acc" {
  name                = "cosmos-acc-mongodb-api"
  location            = azurerm_resource_group.cosmos.location
  resource_group_name = azurerm_resource_group.cosmos.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  consistency_policy { consistency_level = "Session" }
  geo_location {
    location          = azurerm_resource_group.cosmos.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_mongo_database" "mongo" {
  name                = "mongodb-database"
  resource_group_name = azurerm_resource_group.cosmos.name
  account_name        = azurerm_cosmosdb_account.mongo_acc.name
}

resource "azurerm_cosmosdb_mongo_collection" "mongo_coll" {
  name                = "UserCollection"
  resource_group_name = azurerm_resource_group.cosmos.name
  account_name        = azurerm_cosmosdb_account.mongo_acc.name
  database_name       = azurerm_cosmosdb_mongo_database.mongo.name
  shard_key           = "user_id"
  throughput          = 400
}

# --- 4. CASSANDRA API (Dedicated Account) ---
resource "azurerm_cosmosdb_account" "cassandra_acc" {
  name                = "cosmos-acc-cassandra-api"
  location            = azurerm_resource_group.cosmos.location
  resource_group_name = azurerm_resource_group.cosmos.name
  offer_type          = "Standard"
  kind                = "Cassandra"

  consistency_policy { consistency_level = "Session" }
  geo_location {
    location          = azurerm_resource_group.cosmos.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_cassandra_keyspace" "cassandra" {
  name                = "cassandra-keyspace"
  resource_group_name = azurerm_resource_group.cosmos.name
  account_name        = azurerm_cosmosdb_account.cassandra_acc.name
}

resource "azurerm_cosmosdb_cassandra_table" "cassandra_table" {
  name                  = "Users"
  cassandra_keyspace_id = azurerm_cosmosdb_cassandra_keyspace.cassandra.id

  schema {
    column { name = "user_id"; type = "uuid" }
    column { name = "name"; type = "text" }
    partition_key { name = "user_id" }
  }
}
