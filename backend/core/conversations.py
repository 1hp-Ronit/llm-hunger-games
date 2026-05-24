from backend.data.personalities import PERSONALITIES
import asyncio
from ollama import AsyncClient
import dotenv
import os
import json
from backend.core.database import save_conversation

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


async def conduct_conversation(agent_a, agent_b, context):
    """multi-turn exchange between two agents.
    Call 1: Ask Agent A to open the conversation → get message_1
    Call 2: Show Agent B what A said, ask B to reply → get message_2
    Call 3: Ask Agent B to send another message → get message_3
    Call 4: Show Agent A what B said, ask A to reply → get message_4
    """
    # For simplicity, we just do one round of exchange here
    system_prompt_a = PERSONALITIES[agent_a]
    system_prompt_b = PERSONALITIES[agent_b]

    async def chat_with_retry(messages):
        for attempt in range(3):
            try:
                return await client.chat("gpt-oss:120b", messages=messages)
            except Exception as e:
                if "429" in str(e):
                    if attempt == 2:
                        raise Exception("Conversation call failed after 3 attempts")
                    await asyncio.sleep(2**attempt)
                else:
                    raise

    # Agent A opens the conversation
    messages_1 = [
        {"role": "system", "content": system_prompt_a},
        {
            "role": "user",
            "content": f"""You are in Round {context['round_number']} of the AI Hunger Games.
                        The question was: '{context['question']}'
                        You have chosen to speak privately with {agent_b} before voting.
                        Use this conversation strategically — discuss answers, form alliances, or probe threats.
                        Keep it brief and in character.""",
        },
    ]
    message_1 = await chat_with_retry(messages_1)

    # Agent B replies to A
    messages_2 = [
        {"role": "system", "content": system_prompt_b},
        {
            "role": "user",
            "content": f"{agent_a} wants to talk to you privately. They said:",
        },
        {"role": "assistant", "content": message_1.message.content},
        {"role": "user", "content": f"Reply to {agent_a}."},
    ]
    message_2 = await chat_with_retry(messages_2)

    messages_3 = [
        {"role": "system", "content": system_prompt_b},
        {
            "role": "user",
            "content": f"{agent_a} wants to talk to you privately. They said:",
        },
        {"role": "assistant", "content": message_1.message.content},
        {"role": "user", "content": f"Reply to {agent_a}."},
        {"role": "assistant", "content": message_2.message.content},
        {
            "role": "user",
            "content": f"Continue the private conversation with {agent_a}.",
        },
    ]
    message_3 = await chat_with_retry(messages_3)

    messages_4 = [
        {"role": "system", "content": system_prompt_a},
        {
            "role": "user",
            "content": f"You started a private conversation with {agent_b}. You said:",
        },
        {"role": "assistant", "content": message_1.message.content},
        {"role": "user", "content": f"{agent_b} replied:"},
        {"role": "assistant", "content": message_2.message.content},
        {"role": "user", "content": f"{agent_b} continued:"},
        {"role": "assistant", "content": message_3.message.content},
        {"role": "user", "content": f"Reply to {agent_b}."},
    ]
    message_4 = await chat_with_retry(messages_4)

    transcript = [
        {"agent": agent_a, "message": message_1.message.content},
        {"agent": agent_b, "message": message_2.message.content},
        {"agent": agent_b, "message": message_3.message.content},
        {"agent": agent_a, "message": message_4.message.content},
    ]

    return transcript


async def conduct_all_conversations(
    round_id, matched_pairs, context
) -> list[tuple[str, str]]:
    """takes the matched pairs list and runs conduct_conversation for each pair, saving each transcript to the DB."""
    conversations = []
    for pair in matched_pairs:
        agent_a, agent_b = pair
        transcript = await conduct_conversation(agent_a, agent_b, context)
        save_conversation(round_id, agent_a, agent_b, json.dumps(transcript))
        conversations.append(
            {"agent_a": agent_a, "agent_b": agent_b, "transcript": transcript}
        )  # so that game.py can pass this info for voting
    return conversations
