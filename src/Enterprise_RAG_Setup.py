import azure.functions as func
import json
import os
import logging
from openai import AzureOpenAI
from datetime import datetime, timedelta
from azure.identity import DefaultAzureCredential
from azure.monitor.query import MetricsQueryClient

app = func.FunctionApp()

# --- EXISTING HTTP TRIGGER CODE HERE ---
@app.route(route="process_ai", methods=["POST"])
def process_ai(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Processing AI request for GPT-5.3 and Embeddings.')

    try:
        # Parse request body
        req_body = req.get_json()
        user_prompt = req_body.get('prompt')

        if not user_prompt:
            return func.HttpResponse("Please pass a 'prompt' in the request body", status_code=400)

        # Initialize Azure OpenAI Client using environment variables from Terraform
        client = AzureOpenAI(
            azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
            api_key=os.getenv("AZURE_OPENAI_API_KEY"),
            api_version="AZURE_OPENAI_API_VERSION"  # Matches GPT-5.3 preview version
        )

        # 1. Get Chat Completion from GPT-5.3
        chat_completion = client.chat.completions.create(
            model=os.getenv("AZURE_OPENAI_CHAT_DEPLOYMENT"), # Maps to "gpt-53" deployment
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": user_prompt}
            ]
        )
        response_text = chat_completion.choices[0].message.content

        # 2. Get Embeddings from text-embedding-ada-3.2
        embedding_response = client.embeddings.create(
            input=user_prompt,
            model=os.getenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT") # Maps to "text-embedding-ada-32"
        )
        vector_data = embedding_response.data[0].embedding

        # Return consolidated JSON response
        return func.HttpResponse(
            json.dumps({
                "gpt_response": response_text,
                "embedding_vector": vector_data,
                "model_used": "gpt-5.3"
            }),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"Error: {str(e)}")
        return func.HttpResponse(f"Internal Server Error: {str(e)}", status_code=500)

# --- NEW TIMER TRIGGERS ---

# 1. Total Token Count (Every hour)
@app.timer_trigger(schedule="0 0 * * * *", arg_name="myTimer", run_on_startup=False)
def timer_total_tokens(myTimer: func.TimerRequest) -> None:
    tokens = get_openai_metric("ProcessedTokens") # Total combined tokens
    logging.info(f"Monitor: Total Token Count is {tokens}")

# 2. Prompt Token Count (Every hour)
@app.timer_trigger(schedule="0 0 * * * *", arg_name="myTimer", run_on_startup=False)
def timer_prompt_tokens(myTimer: func.TimerRequest) -> None:
    tokens = get_openai_metric("ProcessedPromptTokens")
    logging.info(f"Monitor: Prompt Token Count is {tokens}")

# 3. Completion Token Count (Every hour)
@app.timer_trigger(schedule="0 0 * * * *", arg_name="myTimer", run_on_startup=False)
def timer_completion_tokens(myTimer: func.TimerRequest) -> None:
    tokens = get_openai_metric("GeneratedCompletionTokens")
    logging.info(f"Monitor: Completion Token Count is {tokens}")

# 4. Total Requests (Every hour)
@app.timer_trigger(schedule="0 0 * * * *", arg_name="myTimer", run_on_startup=False)
def timer_total_requests(myTimer: func.TimerRequest) -> None:
    requests = get_openai_metric("TotalCalls")
    logging.info(f"Monitor: Total Request Count is {requests}")

def get_openai_metric(metric_name):
    """Helper to query Azure Monitor for OpenAI metrics"""
    client = MetricsQueryClient(DefaultAzureCredential())
    resource_id = os.getenv("OPENAI_RESOURCE_ID") # Add this to your App Settings
    
    # Query for the last 1 hour
    response = client.query_resource(
        resource_id,
        metric_names=[metric_name],
        timespan=timedelta(hours=1)
    )
    
    for metric in response.metrics:
        for timeseries in metric.timeseries:
            for data in timeseries.data:
                if data.total is not None:
                    return data.total
    return 0