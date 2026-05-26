import random

from backend.core.conversations import (
    ask_all_conversations_request,
    conduct_all_conversations,
    match_pairs,
    parse_conversation_request,
)
from backend.core.voting import ask_all_votes, find_eliminated_agent, parse_vote
from backend.data.questions import QUESTIONS
from backend.data.personalities import PERSONALITIES
from backend.core.database import (
    finish_game,
    save_answers,
    save_game,
    init_db,
    save_round,
    save_votes,
)
from backend.core.agents import ask_all_agents


def update_memories(
    round_number: int,
    question: str,
    eliminated_agent: str,
    raw_votes: list[dict[str, str]],
    conversations,
    agent_memory: dict[str, dict],
    global_summary: list[str],
):
    if eliminated_agent is None:
        return
    # Update global summary
    global_summary.append(
        f"Round {round_number}: {eliminated_agent} eliminated. Question: '{question}'"
    )

    # Update surviving agents
    for agent in agent_memory:
        if agent != eliminated_agent:
            agent_memory[agent]["rounds_survived"] += 1
            agent_memory[agent]["private_talks"].extend(
                [
                    conv
                    for conv in conversations
                    if agent in (conv["agent_a"], conv["agent_b"])
                ]
            )
            vote = next(
                (parse_vote(v["raw"]) for v in raw_votes if v["voter"] == agent), None
            )
            if vote:
                agent_memory[agent]["my_votes_cast"].append(vote.get("vote"))

    # Remove eliminated agent after loop
    del agent_memory[eliminated_agent]


async def run_game(game_id: int):
    active_agents = list(PERSONALITIES.keys())
    round_number = 1

    global_summary = []
    agent_memory = {
        name: {"rounds_survived": 0, "private_talks": [], "my_votes_cast": []}
        for name in active_agents
    }

    while len(active_agents) > 1:
        if round_number > len(QUESTIONS):
            break  
        # 1. Pick a question for this round
        question = QUESTIONS[round_number - 1]
        # 2. Ask all active agents the question and get their answers
        answers = await ask_all_agents(question, active_agents)
        # 3. Save the question and answers to the database
        round_id = save_round(game_id, round_number, question)
        save_answers(round_id, answers)
        # 4. Private Conversation of any agent pair and save it to the db
        # """Commenting out conversation part for now to speed up testing. Will add it back in later."""
        # requests = await ask_all_conversations_request(active_agents)
        # parsed_requests = [
        #     {
        #         "agent": r["agent"],
        #         "talk_to": (parse_conversation_request(r["raw"]) or {}).get(
        #             "talk_to", "none"
        #         ),
        #     }
        #     for r in requests
        # ]
        # matched_pairs = match_pairs(parsed_requests)

        # context = {
        #     "round_number": round_number,
        #     "question": question,
        #     "answers": answers,
        #     "global_summary": global_summary,
        #     "agent_memory": agent_memory,
        # }

        # conversations = await conduct_all_conversations(
        #     round_id, matched_pairs, context
        # )

        conversations = []

        # 5. Conduct voting among agents to eliminate one agent
        raw_votes = await ask_all_votes(
            question,
            answers,
            conversations,
            active_agents,
            agent_memory,
            global_summary,
        )
        eliminated_agent, is_tie = find_eliminated_agent(raw_votes)
        # print(
        #     f"Round {round_number}: eliminated={eliminated_agent}, is_tie={is_tie}, active={active_agents}"
        # )
        if is_tie:
            if len(active_agents) == 2:
                eliminated_agent = random.choice(active_agents)
                active_agents.remove(eliminated_agent)
            else:
                pass  # jury vote later
        else:
            active_agents.remove(eliminated_agent)
        # 6. Update personal and global summary
        update_memories(
            round_number,
            question,
            eliminated_agent,
            raw_votes,
            conversations,
            agent_memory,
            global_summary,
        )
        # 7. Save votes and update active agents list
        parsed_for_db = [
            {
                "voter": v["voter"],
                "voted_for": (parse_vote(v["raw"]) or {}).get("vote"),
                "reason": (parse_vote(v["raw"]) or {}).get("reason"),
            }
            for v in raw_votes
        ]
        save_votes(round_id, parsed_for_db)

        round_number += 1
    winner = active_agents[0]
    finish_game(game_id, winner)
    return winner
