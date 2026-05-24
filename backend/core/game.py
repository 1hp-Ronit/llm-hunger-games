from backend.core.conversations import (
    ask_all_conversations_request,
    conduct_all_conversations,
    match_pairs,
    parse_conversation_request,
)
from backend.core.voting import ask_all_votes, find_eliminated_agent, parse_vote
from backend.data.questions import QUESTIONS
from backend.data.personalities import PERSONALITIES
from backend.core.database import save_answers, save_game, init_db, save_round
from backend.core.agents import ask_all_agents


async def run_game(game_id: int):
    active_agents = list(PERSONALITIES.keys())
    round_number = 1

    while len(active_agents) > 1:
        # 1. Pick a question for this round
        question = QUESTIONS[round_number - 1]
        # 2. Ask all active agents the question and get their answers
        answers = await ask_all_agents(question, active_agents)
        # 3. Save the question and answers to the database
        round_id = save_round(game_id, round_number, question)
        save_answers(round_id, answers)
        # 4. Private Conversation of any agent pair and save it to the db

        requests = await ask_all_conversations_request(active_agents)
        parsed_requests = [
            {
                "agent": r["agent"],
                "talk_to": (parse_conversation_request(r["raw"]) or {}).get(
                    "talk_to", "none"
                ),
            }
            for r in requests
        ]
        matched_pairs = match_pairs(parsed_requests)

        context = {
            "round_number": round_number,
            "question": question,
            "answers": answers,
        }

        conversations = await conduct_all_conversations(
            round_id, matched_pairs, context
        )

        # 5. Conduct voting among agents to eliminate one agent
        raw_votes = await ask_all_votes(question, answers, conversations, active_agents)
        eliminated_agent, is_tie = find_eliminated_agent(raw_votes)
        if is_tie:
            pass
        else:
            active_agents.remove(eliminated_agent)
        # 6. Update personal and global summary

        
        # 7. Save votes and update active agents list
        round_number += 1
