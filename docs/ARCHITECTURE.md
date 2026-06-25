# Architecture — AI Hunger Games

A technical deep-dive into how the system is built.

---

## System Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Web Client                    │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────────┐  │
│  │  Main Screen │ │  Analytics   │ │  Data Explorer  │  │
│  │  (Live Game) │ │  (Charts)    │ │  (DB Drill Down)│  │
│  └──────┬───────┘ └──────┬───────┘ └────────┬────────┘  │
│         │ WebSocket      │ REST             │ REST       │
└─────────┼────────────────┼──────────────────┼───────────┘
          │                │                  │
┌─────────▼────────────────▼──────────────────▼───────────┐
│                      FastAPI Server                      │
│  WS /game/{id}/stream   GET /analytics/*   GET /games   │
│  POST /game/start        GET /game/{id}/results          │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                     Game Engine                          │
│                                                          │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ agents.py│  │ voting.py    │  │ conversations.py  │   │
│  │          │  │              │  │                   │   │
│  │ ask_agent│  │ ask_vote     │  │ ask_convo_request │   │
│  │ parallel │  │ jury_vote    │  │ conduct_convo     │   │
│  │ semaphore│  │ find_elim    │  │ match_pairs       │   │
│  └────┬─────┘  └──────┬───────┘  └─────────┬─────────┘  │
│       │               │                    │             │
│  ┌────▼───────────────▼────────────────────▼──────────┐  │
│  │                    game.py                          │  │
│  │  run_game() → 7 round loop → callbacks → winner    │  │
│  └────────────────────────┬───────────────────────────┘  │
│                           │                              │
│  ┌────────────────────────▼───────────────────────────┐  │
│  │                  database.py                        │  │
│  │  SQLite: games, rounds, answers, votes, convos      │  │
│  └────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                    Ollama Cloud                          │
│                  gpt-oss:120b                            │
└─────────────────────────────────────────────────────────┘
```

---

## Game Loop Detail

```python
async def run_game(game_id, on_round_complete=None, on_round_start=None):
    active_agents = [8 personalities]
    eliminated_agents = []
    global_summary = []
    agent_memory = {each agent: {rounds_survived, private_talks, votes_cast}}

    while len(active_agents) > 1:
        question = QUESTIONS[round_number - 1]

        # Notify frontend round is starting
        await on_round_start({"event": "round_start", "question": question})

        # 8 parallel LLM calls
        answers = await ask_all_agents(question, active_agents)
        save_answers(round_id, answers)

        # Conversation phase
        requests = await ask_all_conversations_request(active_agents)
        matched_pairs = match_pairs(parse_requests(requests))
        conversations = await conduct_all_conversations(round_id, matched_pairs, context)

        # Voting phase
        raw_votes = await ask_all_votes(question, answers, conversations,
                                         active_agents, agent_memory, global_summary)
        eliminated_agent, is_tie = find_eliminated_agent(raw_votes)

        # Tie breaking
        if is_tie:
            eliminated_agent, is_tie, jury_votes = await jury_vote(...)
            if is_tie or eliminated_agent is None:
                break  # no winner

        # Update state
        active_agents.remove(eliminated_agent)
        eliminated_agents.append(eliminated_agent)
        update_memories(round_number, eliminated_agent, raw_votes, ...)
        save_votes(round_id, parsed_votes)

        # Stream to frontend
        await on_round_complete({round, question, answers, conversations, votes, eliminated})

        round_number += 1

    winner = active_agents[0] if len(active_agents) == 1 else None
    finish_game(game_id, winner)
```

---

## Async Architecture

Each round makes approximately 24-32 LLM calls:

```
8 answer calls
8 conversation request calls
4 conversation calls (1 pair × 4 turns) — varies
8 vote calls
────────────────
~28 calls per round × 7 rounds ≈ 196 calls per game
```

All calls within each phase use `asyncio.gather()` with a `Semaphore(3)` to avoid rate limiting:

```python
async def ask_all_agents(question, active_agents):
    semaphore = asyncio.Semaphore(3)  # max 3 concurrent requests

    async def ask_with_semaphore(agent):
        async with semaphore:
            return await ask_agent(agent, question)

    tasks = [ask_with_semaphore(name) for name in active_agents]
    return await asyncio.gather(*tasks)
```

Each call has exponential backoff retry on 429 rate limit errors:

```python
for attempt in range(3):
    try:
        response = await client.chat(...)
        return response
    except Exception as e:
        if "429" in str(e):
            await asyncio.sleep(2 ** attempt)  # 1s, 2s, 4s
        else:
            raise
```

---

## Memory System

Agents have no persistent memory between LLM calls. We solve this with two injected structures:

**Per-agent memory object** (unique to each agent):
```python
{
    "rounds_survived": 4,
    "private_talks": ["Engineer (R2)", "Pragmatist (R4)"],
    "my_votes_cast": ["Poet", "Optimist", "Poet"]
}
```

**Global game summary** (shared by all agents):
```python
[
    "Round 1: Poet eliminated. Question: 'What is the biggest threat to civilization?'",
    "Round 2: Philosopher eliminated. Question: 'What does it mean to live a good life?'"
]
```

Sliding window: last 2 rounds in full detail, older rounds as one-line summaries. This keeps token usage flat regardless of round number.

Both are injected into every voting prompt and conversation prompt. Agents effectively "remember" the game through compressed summaries.

---

## WebSocket Event Stream

The FastAPI WebSocket endpoint streams two event types to Flutter:

**`round_start`** — emitted before LLM calls begin:
```json
{
  "event": "round_start",
  "round": 3,
  "question": "Does free will exist?",
  "active_agents": ["Analyst", "Engineer", "Pragmatist", ...]
}
```

**Round complete** — emitted after elimination:
```json
{
  "round": 3,
  "question": "Does free will exist?",
  "answers": [{"agent": "Analyst", "answer": "..."}, ...],
  "conversations": [{"agent_a": "Engineer", "agent_b": "Pragmatist", "transcript": [...]}],
  "votes": [{"voter": "Analyst", "voted_for": "Poet", "reason": "..."}, ...],
  "eliminated": "Poet",
  "was_tie": false,
  "jury_votes": []
}
```

**`game_over`** — emitted when game ends:
```json
{
  "event": "game_over",
  "winner": "Analyst"
}
```

---

## Database Schema

```sql
games (id, status, winner, started_at)
rounds (id, game_id, round_number, question)
answers (id, round_id, agent, answer)
votes (id, round_id, voter, voted_for, reason, is_jury)
conversations (id, round_id, agent_a, agent_b, transcript)
```

`is_jury` flag on votes distinguishes regular votes from jury tie-breaking votes in analysis.

`transcript` in conversations is stored as a JSON string:
```json
[
  {"agent": "Engineer", "message": "..."},
  {"agent": "Pragmatist", "message": "..."},
  {"agent": "Pragmatist", "message": "..."},
  {"agent": "Engineer", "message": "..."}
]
```

---

## Private Conversation Matching

Agents independently choose who to talk to. A conversation only happens if both agents choose each other (mutual matching):

```python
def match_pairs(requests):
    all_pairs = [(r["agent"], r["talk_to"]) for r in requests]
    matched = [
        (agent, talk_to)
        for agent, talk_to in all_pairs
        if talk_to
        and talk_to != "none"
        and (talk_to, agent) in all_pairs  # mutual
        and agent < talk_to               # dedup
    ]
    return matched
```

Everyone else is notified that the pair talked, but not what was said. This partial information structure is injected into all voting prompts.