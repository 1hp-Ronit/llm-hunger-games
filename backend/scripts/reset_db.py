import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))
from core.database import init_db, DB_PATH

if os.path.exists(DB_PATH):
    os.remove(DB_PATH)
    print("Database deleted")

init_db()
print("Fresh database created")
