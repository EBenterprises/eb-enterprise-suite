import os
import sqlite3
from flask import Flask, jsonify, request, g

app = Flask(__name__)
DB_PATH = os.getenv("DB_PATH", "data.db")

def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DB_PATH)
        db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

def init_db():
    with app.app_context():
        db = get_db()
        db.execute("""
            CREATE TABLE IF NOT EXISTS system_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                payload TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        db.commit()

@app.route("/", methods=["GET"])
def proprietary_status():
    return jsonify({
        "status": "operational",
        "architecture": "proprietary-monolith",
        "node": os.getenv("NODE_ID", "primary-01")
    }), 200

@app.route("/api/execute", methods=["POST"])
def execute_payload():
    data = request.json or {}
    content = data.get("payload", "")
    
    db = get_db()
    cursor = db.cursor()
    cursor.execute("INSERT INTO system_logs (payload) VALUES (?)", (str(content),))
    db.commit()
    
    return jsonify({
        "status": "committed",
        "record_id": cursor.lastrowid
    }), 201

if __name__ == "__main__":
    init_db()
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
