from fastapi import FastAPI, WebSocket
from backend.core.database import (
    save_game, init_db, get_game, get_all_games,
    get_analytics_summary, get_win_counts,
    get_elimination_rounds, get_vote_distribution,
    get_coalition_data
)
from backend.core.game import run_game
from contextlib import asynccontextmanager
import json
from backend.core.database import get_all_games, get_game
from fastapi.middleware.cors import CORSMiddleware
@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/game/start")
async def start():
    game_id = save_game()
    return {"game_id" : game_id}


@app.websocket("/game/{game_id}/stream")
async def game_stream(websocket: WebSocket, game_id: int):
    await websocket.accept()

    async def on_round_start(data: dict):
        await websocket.send_text(json.dumps(data))

    async def on_round_complete(data: dict):
        await websocket.send_text(json.dumps(data))

    winner = await run_game(game_id, on_round_complete, on_round_start)
    await websocket.send_text(json.dumps({"event": "game_over", "winner": winner}))
    await websocket.close()
    
@app.get("/games")
async def list_games():
    return get_all_games()

@app.get("/game/{game_id}/results")
async def game_results(game_id: int):
    return get_game(game_id)

@app.get("/analytics/summary")
async def analytics_summary():
    return get_analytics_summary()

@app.get("/analytics/wins")
async def analytics_wins():
    return get_win_counts()

@app.get("/analytics/eliminations")
async def analytics_eliminations():
    return get_elimination_rounds()

@app.get("/analytics/votes")
async def analytics_votes():
    return get_vote_distribution()

@app.get("/analytics/coalitions")
async def analytics_coalitions():
    return get_coalition_data()