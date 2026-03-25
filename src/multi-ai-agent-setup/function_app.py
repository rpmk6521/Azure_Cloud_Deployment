import azure.functions as func
import azure.durable_functions as df
import os, json, logging
from openai import AzureOpenAI
from azure.cosmos import CosmosClient

app = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)
client = AzureOpenAI(api_key=os.getenv("AZURE_OPENAI_KEY"), api_version="2024-02-01", azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"))

###
# --- HTTP TRIGGER (Entry Point) ---
@app.route(route="start_agent", methods=["POST"])
@app.durable_client_input(client_name="client")
async def http_start(req: func.HttpRequest, client: df.DurableOrchestrationClient):
    user_query = req.get_json().get('query')
    instance_id = await client.start_new("agent_orchestrator", None, user_query)
    return client.create_check_status_response(req, instance_id)

# --- ORCHESTRATOR ---
@app.orchestration_trigger(context_name="context")
def agent_orchestrator(context: df.DurableOrchestrationContext):
    query = context.get_input()
    research = yield context.call_activity("researcher", query)
    report = yield context.call_activity("writer", research)
    yield context.call_activity("logger", {"id": context.instance_id, "report": report})
    return report
#
# --- ACTIVITIES (Agents) ---
@app.activity_trigger(input_name="topic")
def researcher(topic: str):
    res = client.chat.completions.create(model="gpt-4o", messages=[{"role": "user", "content": f"Research: {topic}"}])
    return res.choices[0].message.content

@app.activity_trigger(input_name="data")
def writer(data: str):
    res = client.chat.completions.create(model="gpt-4o", messages=[{"role": "user", "content": f"Summarize: {data}"}])
    return res.choices[0].message.content

@app.activity_trigger(input_name="entry")
def logger(entry: dict):
    cosmos = CosmosClient.from_connection_string(os.getenv("COSMOS_DB_CONNECTION"))
    container = cosmos.get_database_client("ChatDB").get_container_client("Logs")
    container.upsert_item(entry)
