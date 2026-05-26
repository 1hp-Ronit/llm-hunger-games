from backend.core.database import init_db, save_game
from backend.core.game import run_game
import asyncio

if __name__ == "__main__":
    print("Starting game...")
    
    init_db()
    print("Database initialized.")
    game_id = save_game()
    print(f"Created game with id: {game_id}")
    winner = asyncio.run(run_game(game_id))
    
    print(f"Winner: {winner}")
