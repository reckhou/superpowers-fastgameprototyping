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

1. **Glance at project context** — existing files, structure, recent work (2 minutes max)
2. **Propose your approach** — see below for how to handle tech decisions
3. **Get confirmation** — user confirms or adjusts direction, then invoke `writing-plans`

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

Write one entry per meaningful decision. Skip trivial choices (naming, file layout). If no real alternatives were considered for a choice, it's probably not worth logging.

This file is a **draft** — `writing-plans` will append planning-phase decisions and finalize it.
