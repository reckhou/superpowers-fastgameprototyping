---
name: brainstorming
description: "Use when starting a new feature or prototype to quickly align on approach before writing code."
---

# Spike & Prototype Brief

Rapidly align on what you're building and how, then move immediately to implementation.

**Goal:** One focused exchange, not a design ceremony. Prototypes need momentum.

---

## Step 1: Scope Check — Throwaway or Foundation?

Before anything else, answer this:

**Is this throwaway or foundation code?**

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
2. **Identify the one real unknown** — if anything is genuinely ambiguous, ask ONE question
3. **Propose your approach** — one sentence on architecture, one on tech choice if relevant
4. **Get a thumbs up** — confirm or adjust, then invoke `writing-plans`

## What to Skip

- Multiple clarifying questions in sequence
- 2-3 approach comparisons with trade-offs (just pick the right one and state why)
- Written spec documents
- Spec review loops
- Waiting for approval of a design document

## When to Decompose First

If the request spans multiple independent systems (e.g., "build an editor with asset pipeline, scene graph, and property inspector"), split into sub-projects. Brief each separately. Don't try to plan everything at once.

## Output Format

```
Building: [what]
Approach: [how, one sentence]
[Optional: one trade-off or risk worth noting]

Ready to write the plan — any changes?
```

After confirmation (or if no changes needed), immediately invoke `writing-plans`.
