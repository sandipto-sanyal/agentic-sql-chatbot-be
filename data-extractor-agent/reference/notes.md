# MCP server notes (`scripts/run.py`)

Written for: developers working on the data-extractor agent or connecting a client to it.

## What it is
- A FastMCP server named `demo-http`.
- It does not call an LLM itself. When a tool needs model output, it asks the connected client to run the completion through MCP sampling (`sampling/createMessage`). The client chooses the model.
- Planning (the orchestrator loop) also belongs to the client. The `orchestrator` prompt supplies the planner's system prompt.

## Running it
- `python scripts/run.py` uses `streamable-http` by default and serves `http://0.0.0.0:8000/mcp`. The inline comment suggests `127.0.0.1` for local-only.
- `python scripts/run.py --transport stdio` is for clients that launch the server themselves, such as Claude Desktop or MCP Inspector.
- Settings are loaded from `.env` with `load_dotenv(override=True)`.
- Logging goes through `chat_logger.get_logger`.

## Tools

| Tool | Args | What it does | Notes |
|---|---|---|---|
| `get_database_schema` | `database` | Returns the `CREATE TABLE` DDL for every table. | Run it before `query_runner` so the SQL uses real names. |
| `query_runner` | `query`, `database`, `ctx` | Runs SQL and returns the first 50 rows as a markdown table, plus row and column counts. | Appends each query to `employee_agentic_chatbot.sql` with a timestamp. Emits `SubagentMessage` and `QueryRunnerMessage` events. Runs in a thread via `asyncio.to_thread`. |
| `simplify_query` | `query`, `schema`, `ctx` | Rewrites a complex query, such as one with many joins or a timeout, into CTEs. | Uses sampling with `system_prompts/simplify_query.md` and `user_prompts/simplify_query.md`, temperature 0.8. |

Each tool takes its database explicitly. There is no shared connection.

## Prompt
- `orchestrator` returns `system_prompts/orchestrator.md` with `orchestrator_flow_mcp.mmd` inserted as `{flow}`.
- The client fetches this prompt and uses it as the planner's system prompt.

## Events to the UI
- `emit()` sends MCP log notifications, not tool results. The payload is `{type_, toolName, step, content}`.
- The `type_` names match the old websocket events: `SubagentMessage`, `QueryRunnerMessage`.
- Query rows go only to these notifications. The planner receives a short status, so the rows never reach the planning model.

## Files the server reads
- `BASE_DIR` is the folder containing `run.py`, which is `scripts/`.
- `system_prompts/`, `user_prompts/`, `orchestrator_flow_mcp.mmd`, and `employee_agentic_chatbot.sql` are all resolved relative to `scripts/`.
- **Gap:** `scripts/` currently has no `system_prompts/`, `user_prompts/`, or `.mmd` file. The `orchestrator` prompt and `simplify_query` will fail until those files exist.

## Dead code to be aware of
- `GetDashboardDataType` is defined but no tool uses it. It came from the dashboard server.

## Related
- `mysql_connectivity.MySQLConnector` opens a connection per call and must be closed. Each tool closes it in `finally`.
