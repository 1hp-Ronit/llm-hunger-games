from ollama import AsyncClient
import os
import asyncio
from data.questions import QUESTIONS
from data.personalities import PERSONALITIES

client = AsyncClient(
    host="https://ollama.com",
    headers={"Authorization": f"Bearer {os.environ.get('OLLAMA_API_KEY')}"},
)


async def ask_agent(personality_name, question):
    for attempt in range(3):
        try:
            system_prompt = PERSONALITIES[personality_name]
            response = await client.chat(
                "gpt-oss:120b",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": question},
                ],
            )
            return {"agent": personality_name, "answer": response.message.content}
        except Exception as e:
            if "429" in str(e):
                if attempt == 2:  # last attempt, give up
                    raise Exception(f"{personality_name} failed after 3 attempts")
                await asyncio.sleep(2**attempt)
            else:
                raise


async def ask_all_agents(question, active_agents=None):
    agents = active_agents or list(PERSONALITIES.keys())
    semaphore = asyncio.Semaphore(3)

    async def ask_with_semaphore(agent):
        async with semaphore:
            return await ask_agent(agent, question)

    tasks = [ask_with_semaphore(name) for name in agents]
    return await asyncio.gather(*tasks)