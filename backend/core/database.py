import sqlite3
import os
# Defines the path to the SQLite database file, which is located in the "data" directory relative to the current file.
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "game.db")

# Establishes a connection to the SQLite database and initializes the necessary tables for storing game state, rounds, answers, votes, and conversations.

def get_analytics_summary():
    conn = get_connection()
    cursor = conn.cursor()
    
    total_games = cursor.execute(
        "SELECT COUNT(*) as count FROM games WHERE status='finished'"
    ).fetchone()["count"]
    
    most_frequent_winner = cursor.execute(
        "SELECT winner, COUNT(*) as count FROM games WHERE winner IS NOT NULL "
        "GROUP BY winner ORDER BY count DESC LIMIT 1"
    ).fetchone()
    
    avg_rounds = cursor.execute(
        "SELECT AVG(round_count) as avg FROM "
        "(SELECT game_id, COUNT(*) as round_count FROM rounds GROUP BY game_id)"
    ).fetchone()["avg"]
    
    conn.close()
    return {
        "total_games": total_games,
        "most_frequent_winner": dict(most_frequent_winner) if most_frequent_winner else None,
        "avg_rounds": round(avg_rounds, 1) if avg_rounds else 0,
    }


def get_win_counts():
    conn = get_connection()
    cursor = conn.cursor()
    rows = cursor.execute(
        "SELECT winner, COUNT(*) as count FROM games "
        "WHERE winner IS NOT NULL GROUP BY winner ORDER BY count DESC"
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_elimination_rounds():
    conn = get_connection()
    cursor = conn.cursor()
    # Find which round each agent was eliminated in by finding
    # the last round they appeared in answers but not in the next round
    rows = cursor.execute("""
        SELECT a.agent, AVG(r.round_number) as avg_elimination_round
        FROM answers a
        JOIN rounds r ON a.round_id = r.id
        JOIN games g ON r.game_id = g.id
        WHERE g.status = 'finished'
        GROUP BY a.agent
        ORDER BY avg_elimination_round DESC
    """).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_vote_distribution():
    conn = get_connection()
    cursor = conn.cursor()
    rows = cursor.execute(
        "SELECT voted_for, COUNT(*) as count FROM votes "
        "WHERE voted_for IS NOT NULL AND is_jury = 0 "
        "GROUP BY voted_for ORDER BY count DESC"
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_coalition_data():
    conn = get_connection()
    cursor = conn.cursor()
    rows = cursor.execute(
        "SELECT voter, voted_for, COUNT(*) as count FROM votes "
        "WHERE voted_for IS NOT NULL AND is_jury = 0 "
        "GROUP BY voter, voted_for ORDER BY voter"
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_game(game_id):
    conn = get_connection()
    cursor = conn.cursor()
    rounds = cursor.execute("SELECT * FROM rounds WHERE game_id=?", (game_id,)).fetchall()
    result = []
    for r in rounds:
        answers = cursor.execute("SELECT * FROM answers WHERE round_id=?", (r["id"],)).fetchall()
        votes = cursor.execute("SELECT * FROM votes WHERE round_id=?", (r["id"],)).fetchall()
        conversations = cursor.execute("SELECT * FROM conversations WHERE round_id=?", (r["id"],)).fetchall()
        result.append({
            "round": dict(r),
            "answers": [dict(a) for a in answers],
            "votes": [dict(v) for v in votes],
            "conversations": [dict(c) for c in conversations]
        })
    conn.close()
    return result

def get_all_games():
    conn = get_connection()
    cursor = conn.cursor()
    games = cursor.execute("SELECT * FROM games").fetchall()
    conn.close()
    return [dict(g) for g in games]


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