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
        # 5. Conduct voting among agents to eliminate one agent
        # 6. Update personal and global summary 
        # 7. Save votes and update active agents list
        round_number += 1