from flask import Flask, render_template, request
from flask_sock import Sock
import simple_websocket
from typing import *
import json
from employee_agentic_chatbot import orchestrator

app = Flask(__name__)
sock = Sock(app)

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

@sock.route("/ws")
def websocket(ws:simple_websocket.ws.Server):
    try:
        while True:
            msg = str(ws.receive())
            msg = json.loads(msg)
            orchestrator_response, step = orchestrator(user_task=msg['task'], 
                                                       database=msg['database'],
                                                       ws=ws)
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