import asyncio
import os
from ollama import AsyncClient
from backend.data.personalities import PERSONALITIES
import json
from collections import Counter

from dotenv import load_dotenv
load_dotenv()

client = AsyncClient(
    host="https://ollama.com",
    headers={"Authorization": f"Bearer {os.environ.get('OLLAMA_API_KEY')}"},
)


async def ask_vote(
    personality_name: str,
    question: str,
    all_answers: list[dict[str, str]],
    conversations: list[tuple[str, str]],
    agent_memory: dict = {},
    global_summary: list = [],
    is_jury=False,
    active_agents: list = [],
):
    memory = agent_memory.get(personality_name, {})
    summary = global_summary[-2:] if len(global_summary) > 2 else global_summary
    answers_text = "\n\n".join(
        [
            f"{r['agent']}: {r['answer']}"
            for r in all_answers
            if r["agent"] != personality_name  # don't show their own answer
        ]
    )
    for attempt in range(3):
        try:
            if is_jury:
                user_prompt =  f"""You have been eliminated and are now serving as a jury member.

The question was: '{question}'

Remaining agents' answers:
{answers_text}

Global game summary: {summary}

Vote to eliminate one of the remaining agents: {', '.join(active_agents)}
Vote purely on answer quality — you have nothing to lose.

Respond in this exact JSON format with no extra text:
{{"vote": "<agent name>", "reason": "<one sentence>"}}"""
            else:
                user_prompt = f"""You are competing in a game where the worst answer gets eliminated by vote.

The question was: '{question}'

Other agents' answers:
{answers_text}
your memory throughout the game  {memory}
global summary of the game for the past two rounds: {summary}
Agents who spoke privately this round: {conversations}

Vote for the agent with the worst answer. Consider who is a threat to you.
You are {personality_name}. You cannot vote for yourself.

Respond in this exact JSON format with no extra text:
{{"vote": "<agent name>", "reason": "<one sentence>"}}"""

            response = await client.chat(
                "gpt-oss:120b",
                messages=[
                    {"role": "system", "content": PERSONALITIES[personality_name]},
                    {"role": "user", "content": user_prompt},
                ],
            )
            return {"voter": personality_name, "raw": response.message.content}
        except Exception as e:
            if "429" in str(e):
                if attempt == 2:  # last attempt, give up
                    raise Exception(f"{personality_name} failed after 3 attempts")
                await asyncio.sleep(2**attempt)
            else:
                raise


async def ask_all_votes(
    question: str,
    all_answers: list[dict[str, str]],
    conversations: list[tuple[str, str]],
    active_agents=None,
    agent_memory: dict = {},
    global_summary: list = [],
):
    agents = active_agents or list(PERSONALITIES.keys())
    semaphore = asyncio.Semaphore(3)

    async def ask_with_semaphore(agent):
        async with semaphore:
            return await ask_vote(agent, question, all_answers, conversations, agent_memory, global_summary)

    tasks = [ask_with_semaphore(name) for name in agents]
    return await asyncio.gather(*tasks)


def parse_vote(raw_response: str) -> dict[str, str]:
    try:
        first_brace = raw_response.index("{")
        last_brace = raw_response.rindex("}")
        response = raw_response[first_brace : last_brace + 1]
        json_response = json.loads(response)
        return json_response
    except Exception as e:
        return None

# Find eliminated agent when there is a tie 
async def jury_vote(
    question: str,
    answers: list,
    active_agents: list,
    eliminated_agents: list,
    agent_memory: dict,
    global_summary: list,
) -> tuple[str, bool, list]:
    if not eliminated_agents:
        return (None, False, [])
    agents = eliminated_agents
    semaphore = asyncio.Semaphore(3)
    async def ask_jury(agent):
        async with semaphore:
            return await ask_vote(agent, question, answers, [], agent_memory, global_summary, is_jury=True, active_agents=active_agents)
    tasks = [ask_jury(name) for name in agents]
    raw_votes = await asyncio.gather(*tasks)
    eliminated_agent, is_tie = find_eliminated_agent(raw_votes)
    return (eliminated_agent, is_tie, raw_votes)


def find_eliminated_agent(votes: list[dict[str, str]]) -> tuple[str, bool]:
    parsed_votes = []
    for v in votes:
        raw = v.get("raw") if isinstance(v, dict) else None
        if not raw:
            continue
        pv = parse_vote(raw)
        if pv and pv.get("vote"):
            parsed_votes.append(pv["vote"])

    vote_counts = Counter(parsed_votes)
    if not vote_counts:
        return (None, False)

    most_common = vote_counts.most_common()
    top_count = most_common[0][1]
    tied_agents = [agent for agent, cnt in most_common if cnt == top_count]
    if len(tied_agents) > 1:
        return (None, True)
    return (tied_agents[0], False)
    