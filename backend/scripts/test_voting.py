import backend.core.voting as voting
import backend.core.agents as agent
from backend.data.questions import QUESTIONS
import asyncio


results = asyncio.run(agent.ask_all_agents(QUESTIONS[1]))
formatted_results: list[dict[str, str]] = [
    {"agent": str(r["agent"]), "answer": str(r["answer"])}
    for r in results
]

for r in formatted_results:
        print(f"{r['agent']} says: {r['answer']}\n")
        
votes = asyncio.run(voting.ask_all_votes(QUESTIONS[1], formatted_results, []))

print(f"Votes: {votes}")

eliminated_agent = voting.find_eliminated_agent(votes)

print(f"Eliminated agent: {eliminated_agent}")

