from backend.core.database import init_db, save_game
from backend.core.game import run_game
import asyncio

if __name__ == "__main__":
    
    init_db()
    game_id = save_game()
    winner = asyncio.run(run_game(game_id))
    print(f"Winner: {winner}")
