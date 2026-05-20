import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "game.db")

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_connection()
    cursor = conn.cursor()
    
    cursor.executescript("""
        CREATE TABLE IF NOT EXISTS games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            status TEXT DEFAULT 'ongoing',
            winner TEXT,
            started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS rounds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            game_id INTEGER REFERENCES games(id),
            round_number INTEGER,
            question TEXT
        );

        CREATE TABLE IF NOT EXISTS answers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            round_id INTEGER REFERENCES rounds(id),
            agent TEXT,
            answer TEXT
        );

        CREATE TABLE IF NOT EXISTS votes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            round_id INTEGER REFERENCES rounds(id),
            voter TEXT,
            voted_for TEXT,
            reason TEXT
        );

        CREATE TABLE IF NOT EXISTS conversations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            round_id INTEGER REFERENCES rounds(id),
            agent_a TEXT,
            agent_b TEXT,
            transcript TEXT
        );
    """)
    
    conn.commit()
    conn.close()