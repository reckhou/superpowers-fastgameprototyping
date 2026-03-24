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

**Always announce which skill is being activated** before following it:

> "Using superpowers:`skill-name`."

This applies to every skill invocation — brainstorming, writing-plans, executing-plans, systematic-debugging, all of them. It makes the active skill visible in the conversation.

## Fast Path: Bug Reports

**If the user is clearly reporting a bug, unexpected behavior, test failure, or "it's broken" — invoke `systematic-debugging` immediately.** Skip `brainstorming`. The user is not starting something new; they're fixing something broken.

Signs this applies:
- "It's not working", "I'm getting an error", "this is broken"
- Describes unexpected output or behavior
- Paste of a stack trace, error log, or failed test output

## Workflow Sequence

For new features and systems, skills chain in this order:

```
brainstorming        → align on scope and approach (throwaway? foundation?)
       ↓
writing-plans        → task breakdown saved to docs/plans/
       ↓
executing-plans      → implement each task inline, verify, commit
       ↓
finishing-a-development-branch  → merge / push PR / keep / discard
```

Interrupts that can happen at any point:
- Bug or unexpected behavior → `systematic-debugging`
- Working on game logic or a viewmodel → `test-driven-development`
- Working in Godot → `godot-workflow`
- Working on a WPF toolset → `wpf-toolset-patterns`

## Skill Priority for This Fork

For game prototyping and toolset work:

1. **`systematic-debugging`** — when hitting a bug, error, or unexpected behaviour (skip brainstorming)
2. **`brainstorming`** — when starting something new (always ask throwaway vs. foundation)
3. **`executing-plans`** — primary execution path (inline, no subagent overhead)
4. **`test-driven-development`** — for logic and systems (skip for visual/physics work)
5. **`writing-plans`** — when scope needs a task breakdown before coding
6. **`verification-before-completion`** — before claiming anything is done

## What Changed From Upstream

This is a fast-prototyping fork. Key differences:

- `brainstorming` always asks throwaway vs. foundation — then spikes quickly
- `executing-plans` is the **primary** execution path (not the fallback)
- `subagent-driven-development` is optional, not recommended for prototypes
- `using-git-worktrees` is optional — skip for throwaway work
- TDD is scoped to logic/systems — not required for visual/physics/scene setup
- No mandatory review loops (spec reviewer, plan reviewer, per-task quality reviewer)
- Plan task granularity is 15-30 min, not 2-5 min

## Skill Types

**Rigid** (debugging, verification-before-completion): Follow exactly.

**Flexible** (brainstorming, TDD): Adapt to prototype vs. production context — the skill itself tells you when to skip steps.
