"""MCP server for the employee chatbot tools.

This server never calls an LLM itself. Where a tool needs model output (writing SQL,
writing Plotly code, writing a dashboard description), it asks the connected client to
run the completion through MCP sampling (`sampling/createMessage`). The client decides
which model answers.

Planning (the orchestrator loop) also belongs to the client. The `orchestrator` prompt
below returns the system prompt that a client LLM should use to plan calls to these tools.

UI events (progress, tool calls, query results) are sent as MCP log notifications with
the same `type_` names the websocket used. Query rows go only to those notifications,
never into a tool result, so the planning model sees only a masked status.
"""

import asyncio
import json
import os
import traceback
from datetime import datetime
from typing import Any, Dict

import pandas as pd
from dotenv import load_dotenv
from mcp.server.fastmcp import Context, FastMCP
from mcp.types import SamplingMessage, TextContent

import dashboard as dash
from chat_logger import get_logger
from document_search import search_similar
from document_update import update_metadata
from mysql_connectivity import MySQLConnector
from vector_store import store_embedding

load_dotenv(override=True)
logger = get_logger(__name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ORCHESTRATOR_FLOW_MMD = os.environ.get("ORCHESTRATOR_FLOW_MMD", "orchestrator_flow_plotly.mmd")

mcp = FastMCP(
    "demo-http",
    host="127.0.0.1",      # use 127.0.0.1 for local-only
    port=8000,
    stateless_http=True, # no per-session state; easier to scale/deploy
    json_response=True,  # plain JSON replies instead of SSE streams
)


def open_prompt_file(path: str, **kwargs) -> str:
    with open(os.path.join(BASE_DIR, path), "r", encoding="utf-8") as f:
        prompt_template = f.read()
    return prompt_template.format(**kwargs)


async def ask_client_llm(ctx: Context, *, system_prompt: str, user_prompt: str,
                         temperature: float, max_tokens: int = 2000) -> str:
    """Ask the connected client's LLM to complete a prompt (MCP sampling).

    Raises if the client did not advertise sampling support.
    """
    result = await ctx.session.create_message(
        messages=[SamplingMessage(role="user", content=TextContent(type="text", text=user_prompt))],
        system_prompt=system_prompt,
        max_tokens=max_tokens,
        temperature=temperature,
    )
    blocks = result.content if isinstance(result.content, list) else [result.content]
    for block in blocks:
        if isinstance(block, TextContent):
            return block.text
    raise RuntimeError("Client sampling reply contained no text content")


async def emit(ctx: Context, message_type: str, tool_name: str, content: Any, step: int | None = None):
    """Send a UI event to the client as a log notification. It is not part of any tool result."""
    await ctx.session.send_log_message(
        level="info",
        data={"type_": message_type, "toolName": tool_name, "step": step, "content": content},
        logger="agent-events",
        related_request_id=ctx.request_id,
    )


# --------------------------------------------------------------------------- #
# Tools. The docstring is what the client's planner reads to choose a tool, so keep it
# informative. Every tool takes its database explicitly; there is no shared connection.
# --------------------------------------------------------------------------- #

@mcp.tool()
def get_database_schema(database: str) -> str:
    """Gets the CREATE TABLE statement for every table in the database.
    **Must run before query_runner so the SQL uses real table and column names.
    """
    db = MySQLConnector(database_name=database)
    try:
        tables = db.execute_query("SHOW TABLES;")
        schema_parts = []
        if isinstance(tables, pd.DataFrame):
            # SHOW TABLES returns one column; its name depends on the database name
            for name in tables.iloc[:, 0]:
                ddl = db.execute_query(f"SHOW CREATE TABLE `{name}`;")
                if isinstance(ddl, pd.DataFrame) and not ddl.empty and ddl.iloc[0].get("Create Table"):
                    schema_parts.append(ddl.iloc[0]["Create Table"])
        return "\n\n".join(schema_parts)
    finally:
        db.close()


@mcp.tool()
async def query_runner(query: str, database: str, ctx: Context) -> str:
    """Runs a SQL query in the database.
    The rows are shown to the user only. The planner receives a masked status, not the rows.
    """
    with open(os.path.join(BASE_DIR, "employee_agentic_chatbot.sql"), "a", encoding="utf-8") as f:
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        f.write(f"\n\n-- {now}\n")
        f.write(query)

    await emit(ctx, "SubagentMessage", "query_runner", f"Running query:\n```sql\n{query}\n```")

    db = MySQLConnector(database_name=database)
    try:
        query_result = await asyncio.to_thread(db.execute_query, query)
    except Exception:
        return f"Error running query:\n{traceback.format_exc()}"
    finally:
        db.close()

    if not isinstance(query_result, pd.DataFrame):
        return "Request Completed. The query returned no rows."

    markdown = f"""## Data
{query_result.head(50).astype(str).to_markdown(index=False)}
({len(query_result)} Rows, {len(query_result.columns)} Columns)
"""
    await emit(ctx, "QueryRunnerMessage", "query_runner", markdown)
    return markdown


@mcp.tool()
async def simplify_query(query: str, schema: str, ctx: Context) -> str:
    """Simplifies a complex SQL query, for example one with many joins or a timeout, into CTEs.
    Uses the client's LLM through sampling.
    """
    return await ask_client_llm(
        ctx,
        system_prompt=open_prompt_file("system_prompts/simplify_query.md"),
        user_prompt=open_prompt_file("user_prompts/simplify_query.md", query=query, schema=schema),
        temperature=0.8,
    )


@mcp.tool()
def store_user_task(task: str, query: str, database: str) -> Dict[str, str]:
    """Vectorizes and stores the user task and its SQL, so a similar question can reuse the SQL later.
    **Must run after simplify_query produces a SQL query to store.
    """
    mongo_task_id = store_embedding(text=task, metadata={"query": query, "database": database})
    return {"mongodb_object_id": str(mongo_task_id)}


@mcp.tool()
def get_similar_tasks(task: str, database: str) -> Any:
    """Searches earlier user tasks for a similar one and returns the SQL it used.
    **Must run before simplify_query so the SQL is not generated again for a task that was already answered.
    """
    results = search_similar(query=task, database=database)
    return json.loads(json.dumps(results, default=str))


@mcp.tool()
async def generate_plotly_vizualizer_code(query: str, task: str, ctx: Context) -> Dict[str, str]:
    """Generates Plotly chart code and a one-line dashboard description for a SQL query.
    Uses the client's LLM through sampling.
    """
    plotly_code = await ask_client_llm(
        ctx,
        system_prompt=open_prompt_file("system_prompts/generate_plotly_vizualizer_code.md"),
        user_prompt=open_prompt_file("user_prompts/generate_plotly_vizualizer_code.md", query=query, task=task),
        temperature=0,
    )
    dashboard_description = await ask_client_llm(
        ctx,
        system_prompt=open_prompt_file("system_prompts/generate_plotly_vizualizer_code_description.md"),
        user_prompt=open_prompt_file("user_prompts/generate_plotly_vizualizer_code_description.md", query=query),
        temperature=0,
    )
    return {"plotly_code": plotly_code, "dashboard_description": dashboard_description}


@mcp.tool()
def put_plotly_code_in_metadata(mongodb_object_id: str, plotly_code: str, dashboard_description: str) -> Dict[str, int]:
    """Saves the Plotly code and dashboard description on the stored task with the given mongodb_object_id."""
    result = update_metadata(
        object_id=mongodb_object_id,
        metadata={
            "plotly_code": plotly_code,
            "dashboard_description": dashboard_description,
            "update_timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        },
    )
    return {"matched": result.matched_count, "modified": result.modified_count}


# --------------------------------------------------------------------------- #
# Dashboard tools (converted from the Flask /api/* routes in app.py).
# --------------------------------------------------------------------------- #

@mcp.tool()
def get_dashboards(database: str, id: str | None = None) -> Any:
    """Lists the saved dashboards for a database. Pass id to get a single dashboard."""
    return json.loads(json.dumps(dash.get_dashboards(database, id), default=str))


@mcp.tool()
async def get_dashboard_data(database: str, query: str, plotly_code: str, ctx: Context) -> Dict[str, str]:
    """Runs a dashboard's SQL and builds its chart data.
    The rows and chart data are shown to the user only. The planner receives a masked status.
    """
    data = await asyncio.to_thread(dash.get_data, database=database, query=query, trace_directives=plotly_code)
    await emit(ctx, "DashboardDataMessage", "get_dashboard_data", data)
    return {"status": "Request Completed. Dashboard data sent to the UI and masked for privacy reasons"}


@mcp.tool()
def delete_dashboard(database: str, dashboard_id: str) -> Dict[str, int]:
    """Deletes a saved dashboard. The dashboard must belong to the given database."""
    deleted = dash.delete_dashboard(database, dashboard_id)
    if deleted == 0:
        raise ValueError("dashboard not found")
    return {"deleted": deleted}


@mcp.tool()
async def try_dashboard_regeneration(mongodb_object_id: str, query: str, task: str, ctx: Context,
                                     extra_instruction: str = "") -> Dict[str, int]:
    """Regenerates a dashboard's Plotly code and description using the client's LLM (sampling),
    then saves them on the dashboard. extra_instruction is optional, for example 'use a bar chart'.
    """
    task_text = f"{task}\n{extra_instruction}" if extra_instruction else task
    generated = await generate_plotly_vizualizer_code(query=query, task=task_text, ctx=ctx)
    return put_plotly_code_in_metadata(
        mongodb_object_id=mongodb_object_id,
        plotly_code=generated["plotly_code"],
        dashboard_description=generated["dashboard_description"],
    )

# --------------------------------------------------------------------------- #
# Prompt. The client fetches this and uses it as the planner's system prompt.
# --------------------------------------------------------------------------- #

@mcp.prompt(name="orchestrator", description="System prompt for the client LLM that plans calls to these tools.")
def orchestrator_prompt() -> str:
    with open(os.path.join(BASE_DIR, ORCHESTRATOR_FLOW_MMD), "r", encoding="utf-8") as f:
        flow = f.read()
    return open_prompt_file("system_prompts/orchestrator.md", flow=flow)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Employee chatbot MCP server")
    parser.add_argument(
        "--transport",
        choices=["stdio", "streamable-http"],
        default="streamable-http",
        help="stdio for Claude Desktop and Inspector (launched by the client); "
             "streamable-http serves http://127.0.0.1:8000/mcp",
    )
    args = parser.parse_args()
    mcp.run(transport=args.transport)
