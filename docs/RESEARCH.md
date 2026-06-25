# Research Notes — AI Hunger Games

This document tracks the research methodology, preliminary findings, and open questions for the AI Hunger Games project. The goal is an undergraduate research paper analyzing emergent behavior in multi-agent LLM systems.

---

## Research Question

**Do reasoning archetypes have consistent dominance patterns across question domains in a competitive multi-agent LLM elimination system?**

Secondary questions:
- Do agents vote strategically or honestly?
- Does private communication before voting influence survival?
- Does question category (analytical, philosophical, ethical) change which archetype wins?
- Do agents form coalitions, and does coalition membership correlate with survival?

---

## Why This is Novel

Prior work on multi-agent LLM systems focuses on task completion (AutoGPT, LangGraph agents), tool use, or debate formats. This project differs in three ways:

1. **Elimination mechanic** — agents are permanently removed, which forces strategic behavior absent from cooperative systems
2. **Private communication** — the partial information structure (others know a conversation happened but not its content) mirrors real social dynamics
3. **Personality-consistent prompting at scale** — 8 distinct reasoning styles maintained across 7 rounds with compressed memory injection

---

## Methodology

### System Design

- 8 personality archetypes defined by system prompts
- Each round: one question → parallel async LLM responses → optional private conversations → peer voting → elimination
- Memory injection: personal history + compressed global summary (last 2 rounds in full, older rounds as one-line summaries)
- All data persisted to SQLite: answers, votes (with reasons), conversations (full transcripts), game outcomes

### Models Used

- Primary: `gpt-oss:120b` via Ollama cloud
- All 8 personalities use the same underlying model — personality is a prompt construct, not a different model

### Question Categories

Questions are distributed across:
- **Analytical** — factual, empirical, data-driven
- **Philosophical** — open-ended, first-principles, no correct answer
- **Ethical** — moral dilemmas, contested values
- **Practical** — implementation, policy, real-world decisions

### Data Collection

Target: 20-30 games minimum for statistical significance. Each game uses a fixed set of 7 questions. Varied question sets across runs to test category effects.

### Metrics Collected Per Game

- Elimination order (which round each agent was eliminated)
- Vote distribution (how many votes each agent received per round)
- Voting patterns (who voted for whom — coalition detection)
- Private conversation frequency (which pairs talked, how often)
- Answer length per agent per round
- Whether jury vote was triggered

---

## Preliminary Findings

*Based on 8 games. Sample size too small for statistical claims — these are observations for hypothesis generation.*

### Survival Rates

| Personality | Wins | Avg Elimination Round |
|---|---|---|
| Analyst | 5 | — (winner) |
| Skeptic | 1 | — |
| Pragmatist | 1 | — |
| Optimist | 1 | — |
| Poet | 0 | ~1-2 |
| Philosopher | 0 | ~1-3 |
| Engineer | 0 | ~4-5 |
| Contrarian | 0 | ~3-4 |

### Key Observations

**Analyst dominance** — Data-driven reasoning with cited (though often hallucinated) statistics consistently receives fewer elimination votes. Hypothesis: agents across archetypes converge on valuing structured, evidenced answers regardless of their own style.

**Poet early elimination** — Creative metaphorical answers receive high elimination votes on factual/analytical questions. When question category shifts to open-ended or philosophical prompts, Poet survival improves. Suggests category dependence.

**Strategic voting evidence** — Multiple instances of agents citing competitive threat rather than answer quality as elimination reason. Example: Pragmatist voted against Analyst stating *"their data-heavy answer outshines mine and makes me look less authoritative."* This is game-theoretic behavior, not honest quality assessment.

**Alliance formation** — Engineer and Pragmatist engaged in private conversations across 3 consecutive rounds in one game, coordinating answer framing and mutual voting. Both survived longer than average in that run.

**Philosopher performance is question-dependent** — Philosopher consistently eliminated in rounds 1-2 on factual questions (COVID hoax, empirical debates) but survives into later rounds when philosophical questions appear. Strongest evidence so far for question-category effects.

**Citation hallucination** — Analyst fabricates specific statistics and citations ("Gallup 2020", "McKinsey 2023", "Baker et al. 2021") that do not exist. This is a significant limitation: the Analyst wins partly on the *appearance* of rigor rather than actual rigor. Worth a dedicated discussion section.

---

## Limitations

**Same underlying model** — All 8 personalities use the same LLM. The model likely has a "native" reasoning style that may bias it toward Analyst-type answers regardless of system prompt. Running personalities on different model families (Llama vs Mistral vs Gemma) would strengthen the findings.

**Small sample size** — 8 games is insufficient for statistical claims. 20-30 minimum needed.

**Fixed question set** — Using the same 7 questions across runs introduces confounds. Ideally each run uses a randomized question set from a larger bank.

**Citation hallucination** — Analyst wins partly on fabricated authority, not actual empirical reasoning. This should be disclosed as a system behavior, not treated as valid evidence quality.

**No human baseline** — We don't know how humans would vote on the same answers. Without a human baseline we can't say whether the voting patterns reflect genuine quality differences or LLM-specific biases.

---

## Open Questions for Further Investigation

1. Does Analyst still dominate if citations are stripped from all answers before voting?
2. Do private conversations causally increase survival probability, or do strong agents simply talk more?
3. Is the voting bias toward Analyst a property of the question set (too many factual questions) or a general LLM preference for structured responses?
4. Does the Contrarian personality — which argues against consensus — systematically receive more votes because it takes unpopular positions?
5. Do jury voters (eliminated agents) vote differently from active agents — more honestly, or with grudges?

---

## Planned Paper Structure

```
Abstract
1. Introduction — multi-agent systems, motivation, contribution
2. Related Work — LLM debate systems, multi-agent frameworks, persona studies
3. System Design — architecture, prompt engineering methodology, memory system
4. Experimental Setup — models, question corpus, n=X games
5. Results — survival rates, vote patterns, strategic voting evidence, domain analysis
6. Discussion — emergent behaviors, citation hallucination, limitations
7. Conclusion — what this suggests about reasoning archetype dominance
```

---

## Data Location

All game data is stored in `backend/data/game.db`. Use `backend/scripts/view_db.py` for human-readable output or query directly with SQLite for analysis.

Analysis scripts (planned): `backend/scripts/analysis.py`