import sqlite3
from backend.core.database import DB_PATH
import json
def view_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    print("\n=== GAMES ===")
    for row in cursor.execute("SELECT * FROM games"):
        print(f"  Game {row['id']} | Winner: {row['winner']} | Status: {row['status']} | Started: {row['started_at']}")

    print("\n=== ROUNDS & ANSWERS ===")
    for round_row in cursor.execute("SELECT * FROM rounds ORDER BY game_id, round_number"):
        print(f"\n  [Game {round_row['game_id']}] Round {round_row['round_number']}: {round_row['question']}")
        for answer in cursor.execute("SELECT * FROM answers WHERE round_id=?", (round_row['id'],)):
            print(f"    {answer['agent']}: {answer['answer'][:80]}...")

    print("\n=== VOTES ===")
    for round_row in cursor.execute("SELECT * FROM rounds ORDER BY game_id, round_number"):
        print(f"\n  [Game {round_row['game_id']}] Round {round_row['round_number']}:")
        for vote in cursor.execute("SELECT * FROM votes WHERE round_id=?", (round_row['id'],)):
            jury = "[JURY]" if vote['is_jury'] else ""
            print(f"    {jury} {vote['voter']} → {vote['voted_for']}: {vote['reason'][:60]}...")

    print("\n=== CONVERSATIONS ===")
    for conv in cursor.execute("SELECT * FROM conversations"):
        transcript = json.loads(conv['transcript'])
        print(f"\n  Round {conv['round_id']}: {conv['agent_a']} ↔ {conv['agent_b']}")
        for msg in transcript:
            print(f"    {msg['agent']}: {msg['message'][:80]}...")

    conn.close()
if __name__ == "__main__":
    view_db()