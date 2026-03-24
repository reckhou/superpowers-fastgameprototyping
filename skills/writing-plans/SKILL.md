---
name: writing-plans
description: Use when you have a clear idea of what to build and need a task breakdown before touching code
---

# Writing Plans

## Overview

Write a focused implementation plan broken into concrete tasks. Each task should be 15-30 minutes of work — enough to make real progress without being a full feature dump.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## File Structure

Before listing tasks, identify which files will be created or modified and what each one does. Keep it brief — a bulleted list is enough.

## Task Granularity

**Each task is one meaningful unit of work (15-30 minutes):**
- Implement a component or system
- Wire up integration between two pieces
- Add a scene/node setup in Godot
- Write a WPF view + viewmodel pair

Tasks should produce something runnable or testable when complete. Avoid splitting at the micro-step level (no separate "write test", "run test", "write code" steps unless TDD is explicitly required).

## Plan Document Format

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies]

---

## Files

- Create: `path/to/file.cs` — [what it does]
- Modify: `path/to/existing.cs` — [what changes]

---

### Task 1: [Name]

**Files:** `path/to/file.cs`

[What to implement, with key code or structure if non-obvious]

**Verify:** [How to confirm it works — run game, check output, etc.]

---
```

## Remember

- Exact file paths
- Include enough code/structure that the implementer isn't guessing
- Every task ends with a verification step
- Keep it lean — prototype plans don't need exhaustive edge case coverage

## Execution Handoff

After saving the plan, immediately invoke `executing-plans` to implement it inline.

If the plan has truly independent parallel tasks, mention that — but default to sequential inline execution for prototypes.
