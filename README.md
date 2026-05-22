# AI Hunger Games

> 8 LLM personalities compete across 7 elimination rounds. The weakest thinker gets voted out. One survives.

---

## What is this?

AI Hunger Games is a multi-agent LLM simulation where 8 distinct reasoning archetypes — The Analyst, Devil's Advocate, Poet, Engineer, Philosopher, Contrarian, Optimist, and Minimalist — compete by answering questions and voting each other out.

After each round, every surviving agent reads all answers and votes to eliminate the weakest one. The agent with the most votes is eliminated. This continues for 7 rounds until one personality remains.

The interesting question is not who wins — it is **why certain thinking styles consistently outperform others**, and whether agents vote honestly or strategically.

---

## Why it's interesting

This is not a chatbot or a classifier. It is a **multi-agent reasoning system** — one of the most active research areas in AI right now.

Every game produces measurable data:
- Which personality archetypes survive longest
- Whether agents form alliances after private conversations
- Whether answer length or confidence correlates with votes received
- Whether question category (analytical, creative, ethical) changes which archetype wins

That emergent behavior is what makes this research-worthy, not just a fun project.

---

## Features

- 8 hardcoded personality archetypes with distinct reasoning styles
- 7 elimination rounds with parallel LLM calls
- Private conversations between agents before voting — other agents know a conversation happened but not what was said
- Strategic voting — agents consider alliances and threats
- Tie-breaking via jury vote from eliminated agents
- Persistent game history in SQLite for post-game analysis
- Real-time round streaming via WebSockets
- Flutter web frontend with animated agent cards and live vote reveals

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web |
| Backend | FastAPI + Python |
| LLM Runtime | Ollama |
| Database | SQLite |
| Realtime | WebSockets |
| Analysis | Pandas + Matplotlib |

---


## The 8 Personalities

| Agent | Thinking Style |
|---|---|
| Analyst | Data, logic, structured reasoning |
| Devil's Advocate | Challenges the obvious, finds counterarguments |
| Poet | Metaphor, imagery, emotional truth |
| Engineer | Systems thinking, tradeoffs, what works |
| Philosopher | First principles, examines assumptions |
| Contrarian | Resists consensus, distrusts the crowd |
| Optimist | Possibility, progress, what could go right |
| Minimalist | Clarity through simplicity, fewest words |

---

## Round Structure

```
1. Question is asked
2. All agents answer in parallel
3. Agents choose who to speak with privately
4. Private conversations happen (2 exchanges, stored but hidden)
5. All agents vote to eliminate (JSON: vote + reason)
6. Tally votes — highest votes is eliminated
7. Tie → jury vote from eliminated agents
8. Update memories and move to next round
```

---

## Context Management

Agents have no memory between rounds by default. This is solved through:

- **Per-agent memory object** — rounds survived, private talks, vote history, perceived threats
- **Global game summary** — last round in full detail, older rounds as one-line summaries
- Both are injected into every prompt, keeping token usage flat across all rounds

---

## Research Potential

This project is designed to produce a undergraduate research paper analyzing:

- Survival rates by personality archetype across question categories
- Coalition detection — do agents vote for similar thinking styles
- Correlation between answer length, confidence, and votes received
- Strategic vs honest voting behavior after private conversations
- Effect of jury voting on game outcomes

---

## Author

Ronit Kumar — First year Computer Engineering, Army Institute of Technology, Pune.