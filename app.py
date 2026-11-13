from flask import Flask, render_template, request, jsonify
from flask_sock import Sock
import simple_websocket
from typing import *
import json
from employee_agentic_chatbot import orchestrator
from chat_logger import get_logger
import traceback
import os
from flask_cors import CORS
from dashboard import get_dashboards, get_data, delete_dashboard as delete_dashboard_record

app = Flask(__name__)
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

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/get_dashboards", methods=["POST"])
def get_dashobards():
    database = request.json['database']
    id = request.json.get("id")
    dashboards = get_dashboards(database, id)
    return jsonify(dashboards), 200

@app.route("/api/get_data", methods=["POST"])
def get_data_route():
    database = request.json['database']
    query = request.json['query']
    data = get_data(database=database, query=query)
    return jsonify(data), 200

@app.route("/api/delete_dashboard", methods=["DELETE"])
def delete_dashboard():
    database = request.json['database']
    dashboard_id = request.json['dashboard_id']
    deleted = delete_dashboard_record(database, dashboard_id)
    if deleted == 0:
        return jsonify({"error": "dashboard not found"}), 404
    return jsonify({"deleted": deleted}), 200


@sock.route("/ws")
def websocket(ws:simple_websocket.ws.Server):
    try:
        while True:
            msg = str(ws.receive())
            msg = json.loads(msg)
            orchestrator_response, step = "", -1
            try:
                orchestrator_response, step = orchestrator(user_task=msg['task'], 
                                                        database=msg['database'],
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
    

if __name__ == "__main__":
    # Run with Hypercorn for WebSocket support:
    # hypercorn app:app --bind 0.0.0.0:8000
    app.run(debug=False)