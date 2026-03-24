---
name: subagent-driven-development
description: Use when executing a plan with large independent tasks that benefit from isolated context per task
---

# Subagent-Driven Development

Execute a plan by dispatching a fresh subagent per task. Use this when tasks are large and independent enough that context isolation actually helps.

**For most prototype work, use `executing-plans` instead.** This skill adds overhead that slows iteration. Reserve it for tasks that are large, risky, or where you want clean separation of concerns.

## When to Use

- Tasks are large (1+ hour each) and independent
- You want to isolate context between complex tasks
- Working on a codebase where cross-task context bleed is a real risk

When in doubt, use `executing-plans`.

## The Process

For each task:

1. **Dispatch implementer subagent** — provide full task text, relevant file context, architecture summary, and working directory. Do not make the subagent read the plan itself.
2. **Answer any questions** the subagent raises before it starts
3. **Review the result** — read what was committed, spot-check for obvious issues
4. **Mark complete** and move to next task

After all tasks: invoke `finishing-a-development-branch`.

## Implementer Subagent Instructions

Provide the subagent with:
- Full task text (copy from plan, don't link)
- Where this task fits in the overall feature
- Architecture overview (2-3 sentences)
- Working directory path

Expect one of these status reports back:
- **DONE** — proceed
- **DONE_WITH_CONCERNS** — read the concerns, decide if they need addressing
- **NEEDS_CONTEXT** — provide what's missing and re-dispatch
- **BLOCKED** — assess: more context, smaller task, or escalate to human

## No Mandatory Review Loops

Spot-check results as you go. If something looks wrong, fix it in the next task or dispatch a targeted fix. Do not run formal spec-compliance and code-quality review subagents per task — that level of process kills prototype momentum.

Request a code review via `requesting-code-review` at the end if the work is heading toward production.

## Prompt Templates

- `./implementer-prompt.md` - Dispatch implementer subagent
