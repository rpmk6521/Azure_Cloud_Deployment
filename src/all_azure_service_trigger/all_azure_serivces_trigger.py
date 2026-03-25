import azure.functions as func
import azure.durable_functions as df
import logging

app = func.FunctionApp()

# 1. HTTP
@app.route(route="hello")
def http_trigger(req: func.HttpRequest): return func.HttpResponse("OK")

# 2. Queue
@app.queue_trigger(arg_name="msg", queue_name="input-q", connection="AzureWebJobsStorage")
def queue_trigger(msg: func.QueueMessage): logging.info(msg.get_body().decode())

# 3 & 4. Service Bus
@app.service_bus_queue_trigger(arg_name="msg", queue_name="sb-q", connection="SERVICE_BUS_CONNECTION")
def sb_q(msg: func.ServiceBusMessage): logging.info("SB Queue hit")

@app.service_bus_topic_trigger(arg_name="msg", topic_name="sb-t", subscription_name="sub1", connection="SERVICE_BUS_CONNECTION")
def sb_t(msg: func.ServiceBusMessage): logging.info("SB Topic hit")

# 5. Blob (Polling)
@app.blob_trigger(arg_name="myblob", path="samples/{name}", connection="AzureWebJobsStorage")
def blob_trig(myblob: func.InputStream): logging.info(f"Blob: {myblob.name}")

# 6 & 9. Event Grid (Generic and Blob-via-EG)
@app.event_grid_trigger(arg_name="event")
def event_grid_trig(event: func.EventGridEvent): logging.info(event.get_json())

# 7. Event Hub
@app.event_hub_message_trigger(arg_name="hub", event_hub_name="ehub", connection="EVENT_HUB_CONNECTION")
def hub_trig(hub: func.EventHubEvent): logging.info(hub.get_body().decode())

# 8. Cosmos DB
@app.cosmos_db_trigger(arg_name="docs", database_name="db", container_name="items", connection="COSMOS_DB_CONNECTION")
def cosmos_trig(docs: func.DocumentList): logging.info(f"Docs: {len(docs)}")

# 10. SQL Trigger
@app.sql_trigger(arg_name="changes", table_name="dbo.Table", connection_string_setting="SQL_DB_CONNECTION")
def sql_trig(changes: str): logging.info(f"SQL: {changes}")

# 11. Durable Activity
@app.activity_trigger(input_name="name")
def durable_activity(name: str): return f"Hello {name}"
