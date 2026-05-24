from backend.data.personalities import PERSONALITIES
import asyncio
from ollama import AsyncClient
import dotenv
import os
import json

dotenv.load_dotenv()

client = AsyncClient(
    host="https://ollama.com",
    headers={"Authorization": f"Bearer {os.environ.get('OLLAMA_API_KEY')}"},
)


async def ask_conversation_request(personality_name, active_agents):
    for attempt in range(3):
        try:
            system_prompt = PERSONALITIES[personality_name]
            other_agents = [a for a in active_agents if a != personality_name]
            user_prompt = f"""You may choose to speak privately with one agent before voting.
Active agents you can talk to: {', '.join(other_agents)}

Respond in this exact JSON format with no extra text:
{{"talk_to": "<agent name or none>"}}"""
            response = await client.chat(
                "gpt-oss:120b",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
            )
            return {"agent": personality_name, "raw": response.message.content}
        except Exception as e:
            if "429" in str(e):
                if attempt == 2:  # last attempt, give up
                    raise Exception(f"{personality_name} failed after 3 attempts")
                await asyncio.sleep(2**attempt)
            else:
                raise


async def ask_all_conversations_request(active_agents=None):
    agents = active_agents or list(PERSONALITIES.keys())
    semaphore = asyncio.Semaphore(3)

    async def ask_with_semaphore(agent):
        async with semaphore:
            return await ask_conversation_request(agent, active_agents)

    tasks = [ask_with_semaphore(name) for name in agents]
    return await asyncio.gather(*tasks)


def parse_conversation_request(raw_response):
    try:
        first_brace = raw_response.find("{")
        last_brace = raw_response.rfind("}")
        response_json = raw_response[first_brace : last_brace + 1]
        conversation_request = json.loads(response_json)
        return conversation_request
    except Exception as e:
        return None


def match_pairs(requests):
    all_pairs = []
    for r in requests:
        all_pairs.append((r["agent"], r["talk_to"]))

    matched_pairs = [
        (agent, talk_to)
        for agent, talk_to in all_pairs
        if talk_to  # Check for None or empty string
        and talk_to != "none"
        and (talk_to, agent) in all_pairs
        and agent < talk_to
    ]

    return matched_pairs

# async def conduct_conversation(agent_a, agent_b, context):
#     """multi-turn exchange between two agents. """
    