---
name: writing-plans
description: Use when you have a clear idea of what to build and need a task breakdown before touching code
---

# Writing Plans

## Overview

Write a focused implementation plan broken into concrete tasks. Each task should be 15-30 minutes of work — enough to make real progress without being a full feature dump.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

## Before You Write

If brainstorming hasn't been done for this feature — no scope check, no approach alignment — invoke `brainstorming` first. Don't write a plan for something that hasn't been briefly aligned on.

## File Naming

**Save plans to:** `docs/plans/`

**Filename format:** `YYYY-MM-DD-<feature-name>.md`

- Use lowercase kebab-case for the feature name: `inventory-system`, `tile-editor-undo`, `save-file-format`
- Be specific enough to distinguish from other plans: `player-movement` not `movement`
- Date is the day you write the plan, not the day you implement it

Examples:
- `docs/plans/2026-03-24-inventory-system.md`
- `docs/plans/2026-03-24-tile-editor-undo-redo.md`
- `docs/plans/2026-03-24-save-file-v2.md`

## File Structure

Before listing tasks, identify which files will be created or modified and what each one does. Keep it brief — a bulleted list is enough.

If you discover during planning that the scope is larger than expected (many more files, unplanned systems), surface that before writing tasks. Don't silently expand scope.

## Task Granularity

**Each task is one meaningful unit of work (15-30 minutes):**
- Implement a component or system
- Wire up integration between two pieces
- Add a scene/node setup in Godot
- Write a WPF view + viewmodel pair

Tasks should produce something runnable or testable when complete. Avoid splitting at the micro-step level (no separate "write test", "run test", "write code" steps unless TDD is explicitly required).

**If a task feels too large** (you'd need to describe more than ~5 steps to implement it), split it into two tasks.

**If tasks depend on each other**, note it explicitly: `**Depends on:** Task 2`.

## Plan Document Format

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence — what this plan achieves]
**Architecture:** [2-3 sentences covering: what the key components are, how data flows between them, and the one decision that shapes everything else. Also state how the core logic can be exercised independently of the visual/rendering layer — see Headless Testability below.]
**Tech Stack:** [Key technologies — e.g., C# + Godot autoload, WPF + CommunityToolkit.Mvvm]

---

## Progress

- [ ] Task 1: [Name]
- [ ] Task 2: [Name]
- [ ] Task 3: [Name]

---

## Files

- Create: `path/to/file.cs` — [what it does]
- Modify: `path/to/existing.cs` — [what changes and why]

---

### Task 1: [Name]

**Files:** `path/to/file.cs`
[**Depends on:** Task N — if applicable]

[What to implement. Include key signatures, data structures, or patterns if the implementation isn't obvious. Be specific enough that no guessing is needed.]

**Verify:** [Specific observable outcome — not "run the game" but "run the game, open the inventory, confirm items display in a 3-column grid"]

---
```

## Headless Testability

**Design core systems to run independently of visuals and the Godot renderer.** This lets you validate game feel, balance, and progressions at simulation speed — seconds instead of hours of playtesting.

Ask this during planning: *Can this system be driven without a player sitting at the keyboard and without rendering a frame?*

**Patterns to consider:**

| System type | Testability approach |
|---|---|
| Core game loop | Inject an AI that mimics player input — move, attack, collect — and run the loop headless for N ticks |
| Economy / resource systems | Simulate N in-game days in a tight loop, log resource deltas, check for runaway growth or stagnation |
| Breeding / procedural generation | Run 1000 generations in isolation, validate output distribution matches design targets |
| Progression / leveling | Simulate an AI completing all content, verify XP curve and unlock timing |
| Combat balance | Run two agents against each other at varying stats, observe win rates |

**How to implement:**

- Keep core logic in plain C# classes (no Godot Node inheritance) so they can run in `dotnet test` without the engine
- Accept an `IPlayerInput` or equivalent interface — real input in-game, scripted input in tests
- Use `[Tool]` scripts or standalone C# test programs for simulation runs, not manual playtests
- Log aggregate results (averages, min/max, histograms) rather than per-frame output

**Write at least one simulation task in the plan** for any system that involves balance, progression, or emergent behavior. Don't wait until late game to discover the economy breaks after day 50.

---

## Remember

- Exact file paths
- Include enough code/structure that the implementer isn't guessing
- Every task ends with a concrete, specific verification step
- Keep it lean — prototype plans don't need exhaustive edge case coverage
- If scope grows during planning, flag it — don't silently absorb it
- Core systems should be testable headless — design for it from the start

## When to Split Into Multiple Plans

If a feature spans truly independent systems (e.g., "asset pipeline" and "property inspector" don't share code), write separate plans. One plan per coherent system is easier to execute and resume than one mega-plan.

## Execution Handoff

After saving the plan, immediately invoke `executing-plans` to implement it inline.

If the plan has truly independent parallel tasks, mention that — but default to sequential inline execution for prototypes.
