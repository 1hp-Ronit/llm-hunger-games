import sqlite3
from backend.core.database import DB_PATH

def view_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    print("\n=== GAMES ===")
    for row in cursor.execute("SELECT * FROM games"):
        print(dict(row))

    print("\n=== ROUNDS ===")
    for row in cursor.execute("SELECT * FROM rounds"):
        print(dict(row))

    print("\n=== ANSWERS ===")
    for row in cursor.execute("SELECT * FROM answers"):
        print(dict(row))

    print("\n=== VOTES ===")
    for row in cursor.execute("SELECT * FROM votes"):
        print(dict(row))

    print("\n=== CONVERSATIONS ===")
    for row in cursor.execute("SELECT * FROM conversations"):
        print(dict(row))

    conn.close()

if __name__ == "__main__":
    view_db()