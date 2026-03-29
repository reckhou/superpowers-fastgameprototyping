---
name: executing-plans
description: Use when you have a written implementation plan to execute
---

# Executing Plans

## Overview

Load the plan, execute tasks in order, verify each one, move on.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## Before You Start

**Context tip:** If this is a large plan (4+ tasks) or you've been brainstorming and planning in this same session, consider running `/clear` first to free up context window space for implementation. Not required — just a suggestion.

If no plan file exists for this feature, invoke `writing-plans` first. Don't implement without a plan.

## Custom API Configuration (Optional)

> **Note:** All tasks always run **inline** in the current session — never as spawned subprocesses. Subprocesses do not inherit the session's permission grants and will block on tool calls.

At startup, check for a custom API config in this order (first `planExecution` key found wins):
1. `.claude/settings.json` in the project root (project-scoped — highest priority)
2. Platform-appropriate global settings:
   - **Windows**: use Bash to run `echo "$USERPROFILE"` to get the home directory, then Read `<result>/.claude/settings.json`
   - **macOS/Linux**: `~/.claude/settings.json`

If the project settings file exists but has no `planExecution` key, continue to the global settings.

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

> "Custom API config found (`<model>` via `<baseUrl>`). Noted — all tasks will still run inline in this session. Proceed with native inline execution?"

If no config is found, state it and proceed without asking:

> "No custom API config found — proceeding with native inline execution."

Proceed to Step 1.

## The Process

### Step 1: Load and Review Plan

1. Read the plan file
2. Check for any tasks already marked complete (checkboxes `- [x]`) — resume from first incomplete task
3. If anything is unclear or blocked before starting, raise it now
4. Create todos for all remaining tasks, then begin

### Step 2: Execute Each Task

All tasks run **inline** in the current session. Do not spawn subprocesses — they lose session permissions and will block.

For each task:

1. Mark todo as `in_progress`
2. Implement per the plan
3. Run the verification step specified in the plan
4. Commit with the standard message format (see below)
5. **Update the plan file** — check off the task in the Progress section: change `- [ ] Task N` to `- [x] Task N`
6. Mark todo as `completed`
7. Move to next task

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
