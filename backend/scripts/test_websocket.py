import asyncio
import websockets
import json

async def test():
    async with websockets.connect("ws://localhost:8000/game/5/stream") as ws:
        while True:
            msg = await ws.recv()
            data = json.loads(msg)
            if data.get("event") == "game_over":
                print(f"Winner: {data['winner']}")
                break
            print(f"Round {data['round']}: eliminated={data['eliminated']}")

asyncio.run(test())