from fastapi import FastAPI, WebSocket
from backend.core.database import save_game, init_db
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