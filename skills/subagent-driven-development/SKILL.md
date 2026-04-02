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

## Step 0: Check Execution Config

Before starting, read the `planExecution` config (first key found wins):
1. `.claude/settings.json` in the project root
2. **Windows**: run `echo "$USERPROFILE"` in Bash, then Read `<result>/.claude/settings.json`
3. **macOS/Linux**: `~/.claude/settings.json`

If config is found, use **CLI subprocess dispatch** for all tasks (see below).
If no config, fall back to **Agent tool dispatch**.

## The Process

For each task:

1. **Dispatch implementer** — provide full task text, relevant file context, architecture summary, and working directory. Do not make the implementer read the plan itself.
2. **Review the result** — read what was committed, spot-check for obvious issues
3. **Mark complete** and move to next task

After all tasks: invoke `finishing-a-development-branch`.

## CLI Subprocess Dispatch (custom API)

When `planExecution` config is present, dispatch each task by running:

```bash
ANTHROPIC_BASE_URL="<baseUrl>" ANTHROPIC_API_KEY="<apiKey>" \
claude --model <model> --dangerously-skip-permissions -p "<implementer prompt>"
```

Run from the project root. The `--dangerously-skip-permissions` flag bypasses tool approval prompts in the subprocess — the subprocess is isolated and does not inherit the parent session's permissions.

The implementer prompt must be self-contained — include:
- Full task text (copy from plan verbatim)
- Where this task fits in the overall feature
- Architecture overview (2-3 sentences)
- Working directory path
- Exact files to create or modify
- Commit message format: `[plan: <feature>, task-<N>] <description>`

Wait for the subprocess to complete, then verify the output and confirm the commit was made.

Expect one of these outcomes:
- Commit exists in `git log` → **DONE**, proceed
- No commit, output shows blocker → **BLOCKED**, assess: provide more context and re-dispatch, or escalate to human
- Commit exists but output mentions concerns → **DONE_WITH_CONCERNS**, decide if they need addressing

## Agent Tool Dispatch (fallback, no config)

When no `planExecution` config is found, use the Agent tool to dispatch a `general-purpose` subagent per task. Provide the same self-contained prompt described above.

Expect status reports: **DONE**, **DONE_WITH_CONCERNS**, **NEEDS_CONTEXT** (re-dispatch with more info), or **BLOCKED** (escalate).

## No Mandatory Review Loops

Spot-check results as you go. If something looks wrong, fix it in the next task or dispatch a targeted fix. Do not run formal spec-compliance and code-quality review subagents per task — that level of process kills prototype momentum.

Request a code review via `requesting-code-review` at the end if the work is heading toward production.
