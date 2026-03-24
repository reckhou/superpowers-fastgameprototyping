---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

## Instruction Priority

1. **User's explicit instructions** (CLAUDE.md, direct requests) — highest priority
2. **Superpowers skills** — override default system behavior
3. **Default system prompt** — lowest priority

## How to Access Skills

**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded — follow it directly. Never use the Read tool on skill files.

## The Rule

**Check for relevant skills BEFORE any response or action.** If a skill might apply, invoke it.

```
User message → Does a skill apply? → Yes: invoke it first → Then respond
                                    → No: respond directly
```

## Skill Priority for This Fork

For game prototyping and toolset work:

1. **`brainstorming`** — when starting anything new (fast spike, not a ceremony)
2. **`systematic-debugging`** — when hitting a bug or unexpected behaviour
3. **`executing-plans`** — primary execution path (inline, no subagent overhead)
4. **`test-driven-development`** — for logic and systems (skip for visual/physics work)
5. **`writing-plans`** — when scope needs a task breakdown before coding
6. **`verification-before-completion`** — before claiming anything is done

## What Changed From Upstream

This is a fast-prototyping fork. Key differences:

- `brainstorming` is a quick spike brief, not a full design ceremony
- `executing-plans` is the **primary** execution path (not the fallback)
- `subagent-driven-development` is optional, not recommended for prototypes
- `using-git-worktrees` is optional — skip for throwaway work
- TDD is scoped to logic/systems — not required for visual/physics/scene setup
- No mandatory review loops (spec reviewer, plan reviewer, per-task quality reviewer)
- Plan task granularity is 15-30 min, not 2-5 min

## Skill Types

**Rigid** (debugging, verification-before-completion): Follow exactly.

**Flexible** (brainstorming, TDD): Adapt to prototype vs. production context — the skill itself tells you when to skip steps.
