from flask import Flask, render_template, request, jsonify, send_from_directory, abort
from flask_sock import Sock
import simple_websocket
from typing import *
import json
from employee_agentic_chatbot import orchestrator
from chat_logger import get_logger
import traceback
import os
from flask_cors import CORS
from dashboard import get_dashboards, get_data, delete_dashboard as delete_dashboard_record,\
    regenerate_dashboard

from datetime import datetime
from zoneinfo import ZoneInfo

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UI_DIST_DIR = os.path.join(BASE_DIR, "ui_dist")


app = Flask(
    "flask_app",
    static_folder=UI_DIST_DIR,   # absolute path, so root_path no longer matters
    static_url_path="",
    root_path=BASE_DIR,
)

sock = Sock(app)
logger = get_logger(__name__)

CORS_ORIGIN_LIST = os.environ['CORS_ORIGIN_LIST'].split(',')
CORS(
    app,
    resources={r"/api/*": {"origins": CORS_ORIGIN_LIST}},
    methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
    expose_headers=["Content-Disposition"],  # headers JS is allowed to read
    supports_credentials=False,
    max_age=600,  # cache preflight for 10 minutes
)

# Store state: which clients are in which rooms
sessions:Dict[simple_websocket.ws.Server, str] = {}  # {ws: room_name}

class WebsocketResponseType(TypedDict):
    type_: Literal['OrchestratorMessage', 'ToolMessage', "ExitMessage", "ProgressMessage"]
    toolName: Optional[str]
    step: int
    content:str

@app.route("/health_check")
def health_check():
    return jsonify(status="ok")


@app.route("/api/get_dashboards", methods=["POST"])
def get_dashobards():
    database = request.json['database']
    id = request.json.get("id")
    dashboards = get_dashboards(database, id)
    return jsonify(dashboards), 200

@app.route("/api/get_mermaid", methods=['GET'])
def get_mermaid():
    with open(os.environ['ORCHESTRATOR_FLOW_MMD'], 'r') as f:
        mermaid = f.read()
    return jsonify({"mermaid": mermaid}), 200

@app.route("/api/get_data", methods=["GET"])
def get_data_route():
    database = request.args.get('database')
    mongodb_object_id = request.args.get('mongodb_object_id')
    if not database or not mongodb_object_id:
        return jsonify({"error": "database and mongodb_object_id are required"}), 400
    dashboards = get_dashboards(database, id=mongodb_object_id)
    if not dashboards:
        return jsonify({"error": "dashboard not found"}), 404
    metadata = dashboards[0]['metadata']
    data = get_data(database=database,
                    query=metadata['query'],
                    trace_directives=metadata['plotly_code'])
    resp = jsonify(data)
    resp.headers["Cache-Control"] = "public, max-age=60"
    return resp, 200

@app.route("/api/delete_dashboard", methods=["DELETE"])
def delete_dashboard():
    database = request.json['database']
    dashboard_id = request.json['dashboard_id']
    deleted = delete_dashboard_record(database, dashboard_id)
    if deleted == 0:
        return jsonify({"error": "dashboard not found"}), 404
    return jsonify({"deleted": deleted}), 200

@app.route("/api/try_dashboard_regeneration", methods=["POST"])
def dashboard_regeneration():
    output = regenerate_dashboard(
        mongodb_object_id=request.json['mongodb_object_id'],
        query = request.json['query'],
        task = request.json['task'],
        extra_instruction=request.json.get('extra_instruction',"")
    )
    return jsonify(output), 200

@sock.route("/chat")
def websocket(ws:simple_websocket.ws.Server):
    try:
        now = datetime.now(ZoneInfo("Asia/Kolkata")).isoformat().replace(":","_")
        while True:
            msg = str(ws.receive())
            msg = json.loads(msg)
            orchestrator_response, step = "", -1
            try:
                orchestrator_response, step = orchestrator(user_task=msg['task'], 
                                                        database=msg['database'],
                                                        chatsession_timestamp=now,
                                                        ws=ws)
            except Exception:
                orchestrator_response = "Something went wrong while answering"
                step = -1
                tb_text = traceback.format_exc()
                logger.exception(tb_text)

                
            websocket_response:WebsocketResponseType = {
                'type_':"OrchestratorMessage",
                'content':orchestrator_response,
                'step': step,
                'toolName': None
            }
            ws.send(json.dumps(websocket_response))
    finally:
        websocket_response:WebsocketResponseType = {
                        'type_':"ExitMessage",
                        'content':"Exiting Connection Bye...",
                        'toolName': None,
                        'step':-999
                    }
        ws.send(websocket_response)
    

# Serve the React build from ui_dist/. Real files (assets/*.js, *.css, favicon) are served
# as themselves, so the browser gets the right MIME type. Any other path returns index.html,
# so client-side routes such as /chat still load the app.
# Path to the compiled output (adjust to your layout)
# Serve the compiled UI; unknown paths fall back to index.html for client-side routing
@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def serve_ui(path):
    if path.startswith("api/") or path == "health_check":
        abort(404)
    file_path = os.path.join(app.static_folder, path)
    if path and os.path.isfile(file_path):
        return send_from_directory(app.static_folder, path)
    return send_from_directory(app.static_folder, "index.html")
 


if __name__ == "__main__":
    # Run with Hypercorn for WebSocket support:
    # hypercorn app:app --bind 0.0.0.0:8000
    app.run(debug=False)