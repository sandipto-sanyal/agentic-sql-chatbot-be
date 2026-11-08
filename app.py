from flask import Flask, render_template, request
from flask_sock import Sock
import simple_websocket
from typing import *

app = Flask(__name__)
sock = Sock(app)

# Store state: which clients are in which rooms
rooms = {}  # {room_name: set of websocket connections}
user_rooms:Dict[simple_websocket.ws.Server, str] = {}  # {ws: room_name}

@app.route("/")
def index():
    return render_template("index.html")

@sock.route("/ws")
def websocket(ws:simple_websocket.ws.Server):
    # First message from client should be "JOIN room_name"
    join_msg = ws.receive()
    if join_msg and join_msg.startswith("JOIN "):
        room = join_msg.split(" ", 1)[1]
        rooms.setdefault(room, set()).add(ws)
        user_rooms[ws] = room
        ws.send(f"You joined room: {room}")

    try:
        while True:
            msg = ws.receive()
            if msg is None:
                break  # client disconnected

            room = user_rooms.get(ws)
            if room:
                # Broadcast to everyone in the same room
                for conn in list(rooms[room]):
                    try:
                        conn.send(f"[{room}] {msg}")
                    except Exception:
                        rooms[room].discard(conn)
    finally:
        # Cleanup on disconnect
        room = user_rooms.pop(ws, None)
        if room and ws in rooms.get(room, set()):
            rooms[room].discard(ws)

if __name__ == "__main__":
    # Run with Hypercorn for WebSocket support:
    # hypercorn app:app --bind 0.0.0.0:8000
    app.run(debug=False)