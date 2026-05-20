import asyncio
from data.questions import QUESTIONS
from core.agents import ask_all_agents

if __name__ == "__main__":
    results = asyncio.run(ask_all_agents(QUESTIONS[1]))
    for r in results:
        print(f"{r['agent']} says: {r['answer']}\n")
