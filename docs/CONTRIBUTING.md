# Contributing to AI Hunger Games

Thanks for your interest in contributing. This document covers how to get set up, what areas need work, and how to submit changes.

---

## Getting Started

Fork the repo, clone your fork, and follow the setup steps in [README.md](README.md). Make sure both the backend and frontend run locally before making changes.

```bash
git clone https://github.com/YOUR_USERNAME/AI_Hunger_Games
cd AI_Hunger_Games
```

Create a branch for your work:

```bash
git checkout -b feature/your-feature-name
```

---

## Project Areas

### Backend (`backend/`)

The backend is pure Python. Key files:

- `core/agents.py` — LLM calls and personality system. If you want to add new personalities or change how agents answer, start here.
- `core/voting.py` — voting logic, tie breaking, jury vote. If you want to change elimination mechanics, start here.
- `core/conversations.py` — private conversation system. Pair matching logic lives here.
- `core/game.py` — the main game loop. Round orchestration, memory updates, callback system.
- `core/database.py` — all SQLite interactions. New analytics queries go here.
- `api.py` — FastAPI endpoints. New API routes go here.

### Frontend (`frontend/lib/`)

The frontend is Flutter Web. Key files:

- `screens/main_screen.dart` — live game view with WebSocket connection
- `screens/analytics_screen.dart` — historical charts
- `screens/table_screen.dart` — data explorer
- `widgets/agent_circle.dart` — circular agent layout and elimination animations
- `widgets/battle_log.dart` — expandable round event feed
- `services/websocket_service.dart` — WebSocket connection management

---

## Areas That Need Work

If you're looking for something to contribute, these are the most impactful open areas:

**Backend:**
- Add more question categories (technical, creative, historical) with tagging so analytics can show performance by category
- Improve the memory system — currently uses last 2 rounds; experiment with smarter compression
- Add a `GET /analytics/coalitions` visualization endpoint
- Add game replay functionality — re-stream a past game from the DB
- Write `analysis.py` using Pandas for the research paper figures

**Frontend:**
- Coalition detection heatmap (who votes for whom matrix)
- Question category filter on analytics screen
- Agent detail popup — click an agent to see all their answers and votes across rounds
- Better mobile responsiveness

**Research:**
- Run 20+ games across varied question categories
- Document findings in RESEARCH.md
- Generate paper figures

---

## Code Style

**Python:**
- Use type hints on all function signatures
- Async functions for anything that calls the LLM
- Keep functions focused — if a function does more than one thing, split it
- Add a one-line comment above non-obvious logic

**Dart/Flutter:**
- Keep widgets small and focused — split large widgets into smaller private classes
- Use `const` constructors wherever possible
- State management via `setState` for now — don't introduce new state management libraries without discussion

---

## Adding a New Personality

1. Add an entry to `backend/data/personalities.py`:
```python
"YourPersonality": "You are The YourPersonality. [clear, distinct description]. Keep responses short (2-4 sentences)."
```

2. Add an emoji to `agentEmojis` in `frontend/lib/screens/main_screen.dart`

3. Update `activeAgents` list if you're changing the default 8

4. Run a test game to verify the personality behaves distinctly from existing ones

---

## Adding a New Question

Add to `backend/data/questions.py`. Tag it mentally by category (analytical, philosophical, ethical, creative, practical) — we'll add formal tagging later.

Good questions for this game:
- Have no single objectively correct answer
- Allow different reasoning styles to genuinely shine
- Are provocative enough that agents will have strong opinions

---

## Submitting a Pull Request

1. Make sure the backend runs without errors: `python -m backend.main`
2. Make sure the frontend compiles: `flutter build web`
3. Write a clear PR description — what you changed and why
4. Reference any related issues

PRs that include test games showing the change works are strongly preferred over PRs that only change code.

---

## Reporting Issues

Open a GitHub issue with:
- What you expected to happen
- What actually happened
- The error output from the FastAPI terminal or Flutter console
- Which round/game the issue occurred in (if relevant)

---

## Questions

Open a GitHub discussion or reach out directly via the contact info in README.md.