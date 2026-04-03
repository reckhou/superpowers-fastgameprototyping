---
name: brainstorming
description: "Use when starting a new feature or prototype to quickly align on approach before writing code."
---

# Spike & Prototype Brief

Rapidly align on what you're building and how, then move immediately to implementation.

**Goal:** One focused exchange, not a design ceremony. Prototypes need momentum.

---

## Step 1: Scope Check — Always Ask

**Always ask the user explicitly:**

> "Is this throwaway (spike/experiment, will be deleted or rewritten) or foundation (shared system, persisted data, core loop)?"

Use this table to frame the question if it helps:

| Throwaway | Foundation |
|---|---|
| Spike to test an idea | Shared system used by multiple features |
| Will be deleted or completely rewritten | Persisted data format (save files, asset files) |
| Pure visual/physics experimentation | Anything the WPF tool and game both read |
| One-session prototype | Core loop, game manager, inventory, progression |

**If throwaway:** Skip the rest of this skill. Just build. No plan needed.

**If foundation:** Continue below.

### When to Promote a Throwaway
If a throwaway prototype survives into a second session, stop. Plan it properly before it grows roots.

---

## Step 2: Spike Brief (Foundation Code)

1. **Research thoroughly** — see "Research Before Recommending" below
2. **Glance at project context** — existing files, structure, recent work (2 minutes max)
3. **Propose your approach** — see below for how to handle tech decisions
4. **Get confirmation** — user confirms or adjusts direction, then invoke `writing-plans`

### Reading AI-Generated Context (Design Tasks Only)

When reading existing project files during the context glance, check the YAML frontmatter `tags` field. Files tagged `ai-generated` have **not been approved by the user** — treat them as unreviewed drafts, not established decisions.

**Rules for `ai-generated` files:**
- **Do not** treat any content as a concrete design decision that is already locked in
- **Do** use the `Sources` section to find and reference original external sources
- **Do** surface relevant content to the user as a *starting point* or *hypothesis*, clearly flagging it as AI-generated and unreviewed
- **Do not** skip the "Propose your approach" and "Get confirmation" steps on the assumption that an ai-generated file already captured the answer

**Approval via plan confirmation:** If the brainstorm concludes and the user is asked "Happy with this direction? Any changes before I write the plan?" — a "yes" (or explicit instruction to proceed) constitutes approval of the current design direction, including any content from ai-generated files that was surfaced and discussed. No separate document approval step is needed.

This rule applies to **design tasks only** (game design, system design, architecture decisions). It does not affect code-only tasks where ai-generated files are just reference material.

### Research Before Recommending

**Do not rely on training data alone.** Training data may be outdated — libraries change APIs, best practices evolve, new tools emerge. Wrong conclusions at the brainstorming stage waste far more work than the time spent researching.

This research pattern follows the **orchestrator-worker model** ([reference](https://www.anthropic.com/engineering/multi-agent-research-system)): the lead session (Opus) plans research strategy and synthesizes results, while parallel subagents (Sonnet) do the actual searching.

#### Model & Session Requirements

- **The lead session (you) must be Opus.** If the current session is not running on Opus, suggest the user switch with `/model` before proceeding — brainstorming is where wrong conclusions are most expensive and Opus as orchestrator is the highest-leverage use of the capable model.
- **Research subagents MUST use Sonnet** — always pass `model: "sonnet"` to the Agent tool. Sonnet subagents with dedicated context windows outperform a single Opus agent doing all research serially. A model upgrade (Sonnet over Haiku) is a larger performance gain than doubling the token budget on a weaker model.

#### Parallel Research Dispatch

Dispatch **2-5 research subagents in parallel** via the Agent tool, each with `model: "sonnet"` explicitly set, a specific research objective, and clear boundaries to prevent duplication. Scale by complexity:

| Complexity | Subagents | Tool calls each | Example |
|---|---|---|---|
| Simple fact-finding | 1 | 3-10 | "What's the latest Godot 4 version?" |
| Comparison / evaluation | 2-3 | 10-15 each | "Compare ECS libraries for C#" |
| Complex multi-domain research | 4-5 | 15+ each | "Architecture options for multiplayer with rollback" |

Each subagent prompt must include:
- A **specific research objective** (not "research everything about X")
- **Output format**: compressed findings with source URLs — not raw search results
- **Boundary**: what this agent covers vs. what sibling agents cover

#### Query Strategy

Instruct subagents to **start with short, broad queries, then progressively narrow** based on what's available. Overly specific initial queries return few or no results.

#### Source Quality

Prefer **authoritative sources** over SEO-optimized content:
- Official documentation, GitHub repos, RFCs, academic papers
- Established blogs by known practitioners (not content farms)
- Release notes and changelogs for version-specific claims
- If a highly-ranked result looks like SEO filler, skip it and dig deeper

#### Synthesis

After subagents return, the lead session (you) must:
- **Cross-reference findings** — do subagents agree? Flag contradictions
- **Verify critical claims** — if a subagent says "library X supports Y", spot-check against official docs
- **Assess completeness** — are there gaps? Dispatch additional subagents if needed
- **Present with references** — every claim in the final proposal should trace to a source URL

#### Guardrails

- **Be honest about uncertainty** — if research cannot find a definitive answer, say so. Never fabricate references or present guesses as facts
- **Use extended thinking** for planning the research strategy and synthesizing results — deep analysis here prevents rework later
- **Don't over-research simple questions** — if the answer is a quick doc lookup, do it inline. The parallel research pattern is for decisions with real trade-offs

### Clarifying Questions

Ask as many questions as needed to fully understand the problem space. There are no stupid questions at this stage — over-asking is preferable to under-asking.

Cover any relevant dimensions: scope, data formats, user interactions, edge cases, performance expectations, integration points, existing constraints, future extensibility, and team conventions. Surface ambiguities even if they seem obvious.

Ask all questions upfront in a single block (not in sequence) so the user can answer them all at once.

### Proposing an Approach

Always explain your reasoning. Don't just state the decision — state why it's the right call for this prototype.

**For every decision (straightforward or complex):**
- List all viable options, not just the top 2-3
- For each option, provide explicit pros AND cons
- State your recommendation and explain why
- Invite the user to weigh in, mix options, or suggest alternatives

There are no stupid solutions at this stage. A seemingly impractical option may spark the right idea.

Example:
```
Option A: GDScript scene script
  Pros: fast, no compile step, easy to iterate
  Cons: no static typing, harder to share with WPF tool

Option B: C# + autoload
  Pros: static typing, shared with WPF tool, IDE support
  Cons: compile step, more boilerplate, overkill if self-contained

Option C: C# attached script (no autoload)
  Pros: static typing without global singleton overhead
  Cons: harder to access from other scenes

Recommendation: Option A if throwaway, Option B if this will be shared with the WPF tool.
```

## What to Skip

- Written spec documents
- Spec review loops
- Waiting for approval of a design document

## When to Decompose First

If the request spans multiple independent systems (e.g., "build an editor with asset pipeline, scene graph, and property inspector"), split into sub-projects. Brief each separately. Don't try to plan everything at once.

## Output Format

```
Building: [what]
Approach: [how — with reasoning]
[If tech decision: Option A / Option B / Recommendation: X because Y]
[Optional: one trade-off or risk worth noting]

Starting the plan — say stop if you want changes.
```

After presenting the brief, **stop and wait for explicit user confirmation** before proceeding. Ask:

> "Happy with this direction? Any changes before I write the plan?"

Only invoke `writing-plans` once the user confirms (or explicitly says to proceed).

---

## Decision Log (Brainstorming Phase)

Once the user confirms direction, **before invoking `writing-plans`**, write a draft decision log to:

```
docs/decisions/YYYY-MM-DD-<feature-name>-decisions.md
```

Use the same date and feature name slug as the plan file will use.

**Capture every decision made during brainstorming** — scope classification, tech choices, and any rejected alternatives:

```markdown
# Decision Log: [Feature Name]

## Brainstorming Phase — [YYYY-MM-DD]

### Decision: [Short title, e.g. "Scope: Foundation vs Throwaway"]
- **Chosen:** [What was decided]
- **Alternatives considered:** [What else was on the table]
- **Rationale:** [Why this was chosen]
- **Trade-offs accepted:** [What was given up or deferred]

### Decision: [Short title, e.g. "Tech: GDScript vs C# Autoload"]
- **Chosen:** [What was decided]
- **Alternatives considered:** [...]
- **Rationale:** [...]
- **Trade-offs accepted:** [...]
```

**File tagging convention:** All AI-generated `.md` files — including decision logs, research notes, synthesis documents, and any other markdown files created during brainstorming — must include `ai-generated` in their YAML frontmatter tags. Example:

```yaml
tags: [game-design, core-loop, ai-generated]
```

This applies to every `.md` file written by Claude during the brainstorming process, including files written by research subagents.

Write one entry per meaningful decision. Skip trivial choices (naming, file layout). If no real alternatives were considered for a choice, it's probably not worth logging.

This file is a **draft** — `writing-plans` will append planning-phase decisions and finalize it.

---

## Session Save Prompt

After the user confirms direction and the decision log is written, ask:

> "Would you like to save this brainstorming session so you can resume it later? (Say yes to run `/save-session`, or skip if this is a quick throwaway.)"

This prompt should appear:
- After every brainstorming session that reaches the "user confirms direction" stage
- Before invoking `writing-plans`

If the user says yes, invoke the `save-session` skill. If no, proceed directly to `writing-plans` (or end, depending on user intent).

If the project hasn't opted into sessions yet, the `save-session` skill will handle the opt-in prompt — don't duplicate that check here.
