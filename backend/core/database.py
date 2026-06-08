import sqlite3
import os
# Defines the path to the SQLite database file, which is located in the "data" directory relative to the current file.
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "game.db")

# Establishes a connection to the SQLite database and initializes the necessary tables for storing game state, rounds, answers, votes, and conversations.
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
            reason TEXT,
            is_jury INTEGER DEFAULT 0
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
    
# Logic to save game state, rounds, answers, votes, and conversations to the database.
    
def save_game():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO games (status) VALUES (?)", ("ongoing",))
    conn.commit()
    game_id = cursor.lastrowid
    conn.close()
    return game_id

def save_round(game_id, round_number, question):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO rounds (game_id, round_number, question) VALUES (?, ?, ?)",
        (game_id, round_number, question)
    )
    conn.commit()
    round_id = cursor.lastrowid
    conn.close()
    return round_id

def save_answers(round_id, answers):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.executemany(
        "INSERT INTO answers (round_id, agent, answer) VALUES (?, ?, ?)",
        [(round_id, r["agent"], r["answer"]) for r in answers]
    )
    conn.commit()
    conn.close()

def save_votes(round_id, votes, is_jury=False):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.executemany(
        "INSERT INTO votes (round_id, voter, voted_for, reason, is_jury) VALUES (?, ?, ?, ?, ?)",
        [(round_id, v["voter"], v["voted_for"], v["reason"], int(is_jury)) for v in votes]
    )
    conn.commit()
    conn.close()

def save_conversation(round_id, agent_a, agent_b, transcript):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO conversations (round_id, agent_a, agent_b, transcript) VALUES (?, ?, ?, ?)",
        (round_id, agent_a, agent_b, transcript)
    )
    conn.commit()
    conn.close()

def finish_game(game_id, winner):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE games SET status = ?, winner = ? WHERE id = ?",
        ("finished", winner, game_id)
    )
    conn.commit()
    conn.close()
    
if __name__ == "__main__":
    init_db()
    game_id = save_game()
    print(f"Created game with id: {game_id}")