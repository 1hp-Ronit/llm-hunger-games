# Game Flow — AI Hunger Games

Visual breakdown of how a full game runs, how rounds work, and when special mechanics trigger.

---

## Full Game Flow

```mermaid
flowchart TD
    A([Start Game]) --> B[Initialize 8 agents\nactive_agents, memories, global_summary]
    B --> C{Agents remaining > 1?}
    C -- No --> W([Declare Winner])
    C -- Yes --> D{Questions remaining?}
    D -- No --> W
    D -- Yes --> E[Pick question for this round]
    E --> F[Emit round_start event to frontend]
    F --> G[All agents answer in parallel\nasyncio.gather + Semaphore]
    G --> H[Save answers to DB]
    H --> I[Conversation phase]
    I --> J[Voting phase]
    J --> K[Find eliminated agent]
    K --> L{Is there a tie?}
    L -- No --> M[Remove eliminated agent\nfrom active_agents]
    L -- Yes --> N{Eliminated agents\navailable as jury?}
    N -- No --> O([End game\nNo winner])
    N -- Yes --> P[Jury vote]
    P --> Q{Jury tie?}
    Q -- Yes --> O
    Q -- No --> M
    M --> R[Update memories\nglobal + personal]
    R --> S[Save votes to DB]
    S --> T[Emit round_complete event to frontend]
    T --> U[round_number += 1]
    U --> C
```

---

## Round Detail — Conversation Phase

```mermaid
flowchart TD
    A[Ask each agent who they want to talk to\nJSON: talk_to: agent_name or none] --> B[Parse responses]
    B --> C[Match pairs\nboth must choose each other]
    C --> D{Any matched pairs?}
    D -- No --> E[conversations = empty list]
    D -- Yes --> F[For each pair run conduct_conversation]
    F --> G[Agent A opens conversation\n4 LLM calls total — 2 turns each]
    G --> H[Save transcript to DB]
    H --> I[Return list of pairs + transcripts]
    I --> J[Notify all agents:\nwho talked to whom\nnot what was said]
    E --> J
    J --> K[Proceed to voting]
```

---

## Round Detail — Voting Phase

```mermaid
flowchart TD
    A[Each agent receives:\n- All other agents answers\n- Who talked privately\n- Their own personal memory\n- Last 2 rounds of global summary] --> B[Agent votes in JSON format\nvote: agent_name, reason: one sentence]
    B --> C[Parse all votes\nextract agent name + reason]
    C --> D[Count votes per agent\nusing Counter]
    D --> E{Clear winner?\nhighest vote count is unique}
    E -- Yes --> F[Return eliminated_agent, is_tie=False]
    E -- No --> G[Return None, is_tie=True]
    F --> H[Save votes to DB\nis_jury=False]
    G --> I[Trigger jury vote]
```

---

## Tie Breaking — Jury Vote

```mermaid
flowchart TD
    A[Tie detected] --> B{Any eliminated\nagents available?}
    B -- No --> C([End game\nNo winner\nRecord in DB])
    B -- Yes --> D[Jury members = all previously eliminated agents]
    D --> E[Each jury member votes\non remaining active agents answers]
    E --> F[Jury prompt includes:\n- Current question + answers\n- Full game summary\n- Their own personality\n- is_jury=True flag]
    F --> G[Count jury votes]
    G --> H{Jury tie?}
    H -- Yes --> C
    H -- No --> I[Eliminate lowest voted agent]
    I --> J[Save jury votes to DB\nis_jury=True]
    J --> K[Continue game]
```

---

## Memory Update — End of Each Round

```mermaid
flowchart TD
    A[Round ends] --> B{eliminated_agent\nis None?}
    B -- Yes --> C[Skip memory update\ntie with no resolution]
    B -- No --> D[Append to global_summary:\nRound N: agent eliminated. Question: ...]
    D --> E[For each surviving agent:]
    E --> F[rounds_survived += 1]
    F --> G[Append any private talks\nthis round to private_talks list]
    G --> H[Append who they voted for\nto my_votes_cast list]
    H --> I[Delete eliminated agent\nfrom agent_memory dict]
    I --> J[Next round — inject updated\nmemories into all prompts]
```

---

## Memory Injection into Prompts

```mermaid
flowchart LR
    A[global_summary list] --> B{Length > 2?}
    B -- Yes --> C[Take last 2 entries\nsliding window]
    B -- No --> D[Take all entries]
    C --> E[Inject into prompt as\nRecent game history]
    D --> E
    F[agent_memory for this agent] --> G[Inject as\nYour memory]
    E --> H[Final prompt sent to LLM]
    G --> H
    I[System prompt\npersonality definition] --> H
    J[Current question\n+ all other answers] --> H
```

---

## WebSocket Event Timeline

```mermaid
sequenceDiagram
    participant Flutter
    participant FastAPI
    participant GameEngine

    Flutter->>FastAPI: POST /game/start
    FastAPI-->>Flutter: {game_id: 5}

    Flutter->>FastAPI: WS connect /game/5/stream
    FastAPI-->>Flutter: connection accepted

    loop For each round
        GameEngine->>FastAPI: on_round_start callback
        FastAPI-->>Flutter: {event: round_start, round: N, question: ...}

        Note over GameEngine: LLM calls running...
        Note over GameEngine: Conversations...
        Note over GameEngine: Voting...

        GameEngine->>FastAPI: on_round_complete callback
        FastAPI-->>Flutter: {round: N, answers: [...], votes: [...], eliminated: ...}
    end

    GameEngine->>FastAPI: game finished
    FastAPI-->>Flutter: {event: game_over, winner: Analyst}
    FastAPI->>Flutter: close connection
```

---

## Agent State Throughout a Game

```mermaid
stateDiagram-v2
    [*] --> Active: Game starts
    Active --> Active: Survives round
    Active --> Eliminating: Receives most votes
    Eliminating --> Eliminated: Animation completes\nRemoved from circle
    Eliminated --> Jury: Tie occurs in later round
    Jury --> Eliminated: Jury vote cast
    Active --> Winner: Last agent standing
    Winner --> [*]
```

---

## Quick Reference

| Mechanic | When it triggers |
|---|---|
| Private conversations | Every round, before voting |
| Jury vote | When active agents tie on votes |
| No winner | Jury also ties, or jury unavailable (Round 1 tie) |
| Memory injection | Every round, in voting + conversation prompts |
| round_start event | Before any LLM calls begin each round |
| round_complete event | After elimination, before next round |
| game_over event | After while loop exits |