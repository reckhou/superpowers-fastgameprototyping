---
name: executing-plans
description: Use when you have a written implementation plan to execute
---

# Executing Plans

## Overview

Load the plan, execute tasks in order, verify each one, move on.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## Before You Start

If no plan file exists for this feature, invoke `writing-plans` first. Don't implement without a plan.

## Custom API Configuration (Optional)

At startup, check for a custom API config by reading these files in order (first match wins):
1. `.claude/config.json` in the project root (project-scoped — highest priority)
2. `~/.claude/config.json` (global — fallback)

Look for a `planExecution` key:

```json
{
  "planExecution": {
    "baseUrl": "https://your-custom-endpoint.com",
    "apiKey": "your-api-token",
    "model": "your-model-name"
  }
}
```

**Ask once per session** — check conversation history first:
- If the user has already chosen a mode earlier in this session, use that choice silently.
- If this is the first invocation this session and config is present, ask:

> "Custom API config found (`<model>` via `<baseUrl>`). Run tasks via custom API or native Claude?
> - **Custom API** — subprocess per task, uses configured endpoint
> - **Native** — inline execution, current session model"

If no config is found, state it and proceed without asking:

> "No custom API config found — proceeding with native inline execution."

Set **custom API mode** based on the user's answer (or absent config), then proceed to Step 1.

## The Process

### Step 1: Load and Review Plan

1. Read the plan file
2. Check for any tasks already marked complete (checkboxes `- [x]`) — resume from first incomplete task
3. If anything is unclear or blocked before starting, raise it now
4. Create todos for all remaining tasks, then begin

### Step 2: Execute Each Task

For each task, choose the path based on whether custom API mode is active:

---

#### Path A — Inline (default, no config)

1. Mark todo as `in_progress`
2. Implement per the plan
3. Run the verification step specified in the plan
4. Commit with the standard message format (see below)
5. **Update the plan file** — check off the task in the Progress section: change `- [ ] Task N` to `- [x] Task N`
6. Mark todo as `completed`
7. Move to next task

---

#### Path B — Custom API subprocess (config present)

1. Mark todo as `in_progress`
2. Construct a task prompt (see format below) and dispatch via Bash:

```bash
ANTHROPIC_BASE_URL=<baseUrl> ANTHROPIC_API_KEY=<apiKey> \
  claude --model <model> -p "<task prompt>"
```

3. Wait for subprocess to complete. Expect one of:
   - `DONE` — implementation complete, proceed
   - `DONE_WITH_CONCERNS: <details>` — review concerns, decide if action needed
   - `BLOCKED: <reason>` — stop and assess; provide more context or escalate
4. Commit the changes with the standard message format (see below)
5. **Update the plan file** — check off the task: change `- [ ] Task N` to `- [x] Task N`
6. Mark todo as `completed`
7. Move to next task

**Task prompt format for subprocess:**
```
Working directory: <absolute path>
Task <N>: <full task description from plan>
Architecture context: <2-3 sentence summary of the feature/codebase>

Implement this task exactly as described. Run the verification step when done.
Do NOT commit — just implement and verify.
Reply with one of: DONE / DONE_WITH_CONCERNS:<details> / BLOCKED:<reason>
```

### Step 3: Finish Up

After all tasks complete:
- Invoke `finishing-a-development-branch` to merge, push PR, or keep as-is

## Commit Message Format

**When executing a plan**, every commit references the plan and task for traceability:

```
[plan: <feature-name>, task-<N>] <imperative description>

Examples:
[plan: inventory-system, task-1] Add ItemData resource class
[plan: tile-editor-undo, task-3] Wire undo stack to editor toolbar
[plan: save-file-v2, task-2] Implement binary serializer for SaveData
```

- `<feature-name>` matches the plan filename (without date and `.md`)
- `<imperative description>` starts with a verb: Add, Implement, Wire, Fix, Extract, Move
- Keep it under 72 characters total

**When no plan exists** (hotfix, iteration tweak), use conventional commits:

```
feat: add double-jump to player controller
fix: correct item stack count on pickup
chore: remove unused signal connections
```

## Resuming a Partially-Completed Plan

If returning to a plan from a previous session:

1. **Read the plan file** — check the **Progress** section at the top; tasks marked `- [x]` are done, `- [ ]` are pending
2. **Trust prior completion** — do not re-verify completed tasks; start from the first unchecked task
3. **Create todos only for remaining tasks**, then begin
4. **If something feels broken** when you start a new task, investigate it then — don't pre-emptively re-run old verifications

The plan file is the source of truth. If the todo system doesn't match the file, trust the file.

## When to Stop and Ask

Stop immediately if:
- A blocker prevents starting or continuing a task
- The plan has a gap that can't be worked around
- Verification fails and the cause is unclear

Ask rather than guess.

## Remember

- Follow the plan — don't improvise features not in it
- Verify each task before marking complete
- Commit and check the plan checkbox after each task
- Never implement on main/master without explicit consent
