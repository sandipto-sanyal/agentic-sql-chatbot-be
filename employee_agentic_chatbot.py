import os
import sys

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage, ToolMessage
from langchain_core.tools import tool, InjectedToolArg
from langchain_openai import AzureChatOpenAI, ChatOpenAI
from langchain_core.messages import message_to_dict
# from azure.identity import DefaultAzureCredential, get_bearer_token_provider
import json
from typing import *
from dotenv import load_dotenv
from mysql_connectivity import MySQLConnector
from datetime import datetime
import traceback
import pandas as pd
from simple_websocket.ws import Server
from document_update import update_metadata

# load the RAG components
from vector_store import store_embeddings, store_embedding
from document_search import search_similar
from document_update import update_metadata
from datetime import datetime
from chat_logger import get_logger
load_dotenv(override=True)

logger = get_logger(__name__)

# --------------------------------------------------------------------------- #
# Azure OpenAI configuration.
#
# AzureChatOpenAI reads these from the environment (set them in your .env):
#   AZURE_OPENAI_ENDPOINT   e.g. https://my-resource.openai.azure.com/
#   AZURE_OPENAI_API_KEY    your Azure OpenAI key
#   OPENAI_API_VERSION      e.g. 2024-10-21
#
# On Azure you reference a *deployment name* (what you named the model when you
# deployed it), not the base model name. Set the two below to your deployments.
# --------------------------------------------------------------------------- #


ORCHESTRATOR_MODEL = os.environ["ORCHESTRATOR_MODEL"]
SUBAGENT_MODEL = os.environ["SUBAGENT_MODEL"]
ORCHESTRATOR_FLOW_MMD = os.environ['ORCHESTRATOR_FLOW_MMD']

def open_prompt_file(path:str, **kwargs)-> str:
    with open(path, "r", encoding="utf-8") as f:
        prompt_template = f.read()
    return prompt_template.format(**kwargs)

def _subagent_llm(temperature: float) -> AzureChatOpenAI | ChatOpenAI:
    # low temperature: precise and concise output
    # high temperature: creative varied output
    # return ChatOpenAI(model=SUBAGENT_MODEL, temperature=temperature)
    # azure openai deployment
    return AzureChatOpenAI(azure_deployment=SUBAGENT_MODEL, 
                           api_version="2025-04-01-preview", 
                           temperature=temperature
                           )
    


# --------------------------------------------------------------------------- #
# Sub-agents — each is a focused LLM call exposed to the orchestrator as a tool.
# The docstring is the description the orchestrator uses to route work, so keep
# it informative.
# --------------------------------------------------------------------------- #

@tool
def get_database_schema(db: Annotated[MySQLConnector, InjectedToolArg],
                        ws: Annotated[Server | None, InjectedToolArg] = None) -> str:
    '''Gets the database schema (CREATE TABLE DDL for every table) for the employees db.
    ** This agent has to be mandatorily run first before query_runner
    '''
    print("\t[get_database_schema] invoked")
    # 1. List all tables in the database
    tables = db.execute_query("SHOW TABLES;")
    # SHOW TABLES returns rows like {"Tables_in_employees": "departments"}

    # 2. Get the full DDL for each table
    schema_parts = []
    if isinstance(tables, pd.DataFrame):
        for index, row in tables.iterrows():
            name = row['Tables_in_employees']
            ddl = db.execute_query(f"SHOW CREATE TABLE `{name}`;")
            # SHOW CREATE TABLE returns {"Table": ..., "Create Table": "CREATE TABLE ..."}
            if isinstance(ddl, pd.DataFrame) and ddl.iloc[0].get("Create Table"):
                schema_parts.append(ddl.iloc[0]["Create Table"])

    return "\n\n".join(schema_parts)

@tool
def query_runner(query: str,
                 db: Annotated[MySQLConnector, InjectedToolArg],
                 ws: Annotated[Server | None, InjectedToolArg] = None):
    '''Runs a query in the employees database'''
    print("\t[query_runner] invoked")
    # save the query in file
    with open("employee_agentic_chatbot.sql", "a") as f:
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        f.write(f"\n\n-- {now}\n")
        f.write(query)
    # execute the query
    send_ws_message(server_message={
        'type_': 'SubagentMessage',
        'toolname':'query_runner',
        'step': None,
        'content': "Connecting to DB"
        
    })
    try:
        content = f"""Running query:
```sql
{query}
```"""
        send_ws_message(server_message={
                'type_': 'SubagentMessage',
                'toolname':'query_runner',
                'step': None,
                'content': content
            }, ws=ws)
        query_result = db.execute_query(query)
        if isinstance(query_result, pd.DataFrame):
            markdown = f"""# Final Answer
## Data
{query_result.astype(str).to_markdown(index=False)}
({len(query_result)} Rows, {len(query_result.columns)} Columns)
"""
            send_ws_message(server_message={
                            'type_': 'QueryRunnerMessage',
                            'toolname':'query_runner',
                            'step': None,
                            'content': markdown
                        }, ws=ws)
            return "Request Completed. Result masked and not presented to LLM for privacy reasons"
    except:
        return f"Error getting schema:\n{traceback.format_exc()}"


@tool
def simplify_query(query: str,
                   schema:str,
                   ws: Annotated[Server | None, InjectedToolArg] = None) -> str:
    """This method will simplify a complex query forming multiple joins or timeout is faced"""
    subagent_llm = _subagent_llm(temperature=0.8)
    query_simplification_system_prompt = open_prompt_file("system_prompts/simplify_query.md")
    prompt = open_prompt_file("user_prompts/simplify_query.md", query=query, schema=schema)
    subagent_messages = [
        SystemMessage(query_simplification_system_prompt),
        HumanMessage(prompt)
    ]
    message = subagent_llm.invoke(subagent_messages)
    return str(message.content)


@tool
def store_user_task(task:str,
                    query:str,
                    database:Annotated[str, InjectedToolArg],
                    ws:Annotated[Server | None, InjectedToolArg]=None):
    """Vectorizes and Stores the user task and associated SQL for retrieval of SQL query later
    **Must run after simplify_query produces a SQL query to store
    """
    mongo_task_id = store_embedding(text=task, 
                                    metadata={'query':query, 'database':database})
    return {"mongodb_object_id": str(mongo_task_id)}

@tool
def get_similar_tasks(task:str, 
                      database:Annotated[str, InjectedToolArg],
                      ws:Annotated[Server | None, InjectedToolArg]=None):
    """Searches similar task user presented to the chatbot and retrieves the SQL associated
    **Must run before simplify_query so that we do not re-compute the SQL for task which user has already asked before.
    """
    collections = search_similar(query=task, database=database)
    return collections

@tool
def generate_plotly_vizualizer_code(query:str,
                                    ws:Annotated[Server | None, InjectedToolArg]=None
                                    ) -> Dict[str, str]:
    """Generates a Plotly based code for a given query."""
    llm = _subagent_llm(temperature=0)
    plotly_code_prompt = open_prompt_file("user_prompts/generate_plotly_vizualizer_code.md",query=query)
    messages = [
        SystemMessage(open_prompt_file("system_prompts/generate_plotly_vizualizer_code.md")),
        HumanMessage(plotly_code_prompt)
    ]
    plotly_code = llm.invoke(messages)
    
    # generate dashboard description
    dashboard_description_prompt = open_prompt_file("user_prompts/generate_plotly_vizualizer_code_description.md", query=query)
    messages = [
        SystemMessage(open_prompt_file("system_prompts/generate_plotly_vizualizer_code_description.md")),
        HumanMessage(dashboard_description_prompt)
    ]
    dashboard_description = llm.invoke(messages)
    return {
        "plotly_code": str(plotly_code.content),
        "dashboard_description":str(dashboard_description.content)
    }

@tool
def put_plotly_code_in_metadata(mongodb_object_id:str,
                                plotly_code:str,
                                dashboard_description:str,
                                ws:Annotated[Server | None, InjectedToolArg]=None
                                ):
    """Updates the metadata for mongodb entry for given mongodb_object_id and add the plotly code"""
    result = update_metadata(object_id=mongodb_object_id,
                    metadata={
                        "plotly_code": plotly_code,
                        "dashboard_description":dashboard_description,
                        "update_timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        })
    return {"matched":result.matched_count,
            "modified":result.modified_count
            }
    
    

def message_text(message: AIMessage) -> str:
    """Return the visible text of a model reply, or "" if it has none.

    Reasoning models return `content` as a list of blocks (e.g. a 'reasoning' block
    followed by a 'text' block), so only the 'text' blocks are joined here.
    """
    if isinstance(message.content, str):
        return message.content
    return "".join(
        block.get("text", "")
        for block in message.content
        if isinstance(block, dict) and block.get("type") == "text"
    )


def send_ws_message(server_message:Dict[Any, Any], ws:Server|None = None):
    logger.info("ws_message sent=%s payload=%s", isinstance(ws, Server),
                json.dumps(server_message, default=str, ensure_ascii=False))
    if isinstance(ws, Server):
        ws.send(json.dumps(server_message))
        
def dump_messages(messages:List[SystemMessage | HumanMessage | AIMessage | ToolMessage]):
    # no colons: Windows does not allow ':' in file names
    now = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    serialized_messages = [
    message_to_dict(message) for message in messages
    ]
    with open(f"./memory/{now}.json", "w", encoding="utf-8") as f:
        json.dump(serialized_messages, f, indent=4, ensure_ascii=False, default=str)        
        

def orchestrator(user_task: str, 
                 database:str,
                 max_steps: int = 8,
                 ws:Server|None=None) -> Tuple[str, int]:
    """Drive the multi-agent workflow until the orchestrator produces a final answer."""
    with open(ORCHESTRATOR_FLOW_MMD, "r") as f:
        flow = f.read()
    ORCHESTRATOR_SYSTEM_PROMPT = open_prompt_file("./system_prompts/orchestrator.md", flow=flow)
    SUBAGENTS = [
        get_database_schema, 
        query_runner, 
        simplify_query, 
        store_user_task,
        get_similar_tasks,
        generate_plotly_vizualizer_code,
        put_plotly_code_in_metadata
            ]
    TOOLS_BY_NAME = {t.name: t for t in SUBAGENTS}

    # chat completions API
    # orchestrator = AzureChatOpenAI(
    #     azure_deployment=ORCHESTRATOR_MODEL,
    #     api_version="2025-04-01-preview",
    #     temperature=0.2
    # ).bind_tools(SUBAGENTS)
    
    # for reasoning
    orchestrator = AzureChatOpenAI(
        azure_deployment=ORCHESTRATOR_MODEL,
        api_version="2025-04-01-preview",
        use_responses_api=True,
        reasoning={"effort": "medium"},   # "low" | "medium" | "high"
    ).bind_tools(SUBAGENTS)

    # orchestrator = ChatOpenAI(model=ORCHESTRATOR_MODEL, temperature=0.2).bind_tools(SUBAGENTS)

    messages:List[SystemMessage | HumanMessage | AIMessage | ToolMessage] = [
        SystemMessage(ORCHESTRATOR_SYSTEM_PROMPT),
        HumanMessage(user_task),
    ]
    # One database connection per orchestrator invocation, shared by all sub-agents
    # that need it. MySQLConnector connects lazily, so no round-trip happens until
    # the first query runs.
    connected_db = MySQLConnector(database_name=database)
    # sub-agents that receive the shared connection as an injected argument
    DB_TOOLS = {get_database_schema.name, query_runner.name}
    VECTORIZER_TOOLS = {store_user_task.name, get_similar_tasks.name}
    logger.info("orchestrator start database=%s max_steps=%s task=%r", database, max_steps, user_task)
    try:
        for step in range(1, max_steps+1):
            print(f"\n[orchestrator] planning step {step}...")
            send_ws_message(server_message={
                "type_":"ProgressMessage",
                "content": f"[orchestrator] planning step {step}",
                "step": step
            }, ws=ws)
            ai_message = orchestrator.invoke(messages)
            messages.append(ai_message)
            logger.info("step=%d ai_message content=%s tool_calls=%s", step,
                        json.dumps(ai_message.content, default=str, ensure_ascii=False),
                        json.dumps(ai_message.tool_calls, default=str, ensure_ascii=False))

            # No tool calls and some text => the orchestrator has produced the final answer.
            if not ai_message.tool_calls:
                final_answer = message_text(ai_message)
                if final_answer:
                    logger.info("orchestrator done step=%d final_answer=%r", step, final_answer)
                    return final_answer, step
                # Reasoning-only reply (no text, no tool calls): keep it in the history and ask again.
                # max_steps still bounds the retries.
                logger.warning("step=%d reply had no text and no tool calls; retrying", step)
                continue

            # Execute each requested sub-agent and feed results back.
            for call in ai_message.tool_calls:
                agent = TOOLS_BY_NAME.get(call["name"])
                send_ws_message({"type_": "ProgressMessage",
                                 "toolName": call["name"],
                                 "step": step,
                                 "content": f"""Running {call["name"]}({call["args"]})"""
                                 }, ws)
                injected = {"ws": ws}
                if call["name"] in DB_TOOLS:
                    injected["db"] = connected_db
                elif call["name"] in VECTORIZER_TOOLS:
                    injected["database"] = database
                result = (
                    agent.invoke({**call["args"], **injected})
                    if agent
                    else f"ERROR: unknown sub-agent '{call['name']}'"
                )
                logger.info("step=%d tool=%s args=%s result=%s", step, call["name"],
                            json.dumps(call["args"], default=str, ensure_ascii=False),
                            json.dumps(result, default=str, ensure_ascii=False))
                messages.append(ToolMessage(content=result, tool_call_id=call["id"]))
                send_ws_message({"type_":"ToolMessage",
                                "toolName":call["name"],
                                "step": step,
                                "content":result
                                }, ws)
    finally:
        dump_messages(messages)
        connected_db.close()

    logger.warning("orchestrator hit max_steps=%s without a final answer", max_steps)
    return (
        "Reached the maximum number of steps without a final answer. "
        "Consider raising `max_steps` or simplifying the task."
    )

if __name__ == '__main__':
    while True:
        print("*"*100)
        query = input("Enter your query. Press CTRL + C to quit: ")
        orchestrator_response = orchestrator(user_task=query)
        print("Agent Response::::\n", orchestrator_response)
    

