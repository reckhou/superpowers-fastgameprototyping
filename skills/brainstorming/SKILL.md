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

### Proposing an Approach

Always explain your reasoning. Don't just state the decision — state why it's the right call for this prototype.

**For straightforward cases (one obvious approach):**
- State the approach with a 1-2 sentence explanation of why it fits
- Note any trade-off or risk worth flagging

**For genuine tech decisions (multiple viable options):**
- Present 2-3 options with one-line pros/cons each
- State your recommendation and explain why
- Invite the user to weigh in before proceeding

Example:
```
Option A: GDScript scene script — fast, no compile step, enough for this scope
Option B: C# + autoload — better if this system will be shared with the WPF tool

Recommendation: Option A, since this is self-contained to the scene.
Your call if you expect this to grow.
```

**For scope or architecture unknowns:**
- Ask ONE focused question before proposing
- Don't ask multiple questions in sequence

## What to Skip

- Multiple clarifying questions in sequence (ask ONE if genuinely needed)
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

After confirmation (or no objection), immediately invoke `writing-plans`.
