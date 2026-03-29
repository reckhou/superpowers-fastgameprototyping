---
name: session-config
description: Use at the start of any conversation when no specific workflow skill (brainstorming, executing-plans, systematic-debugging, iterating-on-feedback, etc.) has been triggered. Handles session-wide configuration — currently API mode selection for plan execution.
---

# Session Config

Lightweight session initializer. Runs once when no other skill applies.

## When to Invoke

- A new conversation begins with a small task, quick fix, or casual request
- No workflow skill (brainstorming, executing-plans, debugging, etc.) has been triggered yet this session
- The user manually invokes `/switch-api` to change API mode mid-session

Do NOT invoke this if a workflow skill has already been triggered this session — those skills check for the API preference themselves.

## The Process

### Step 1: Check if Already Configured

Scan conversation history. If the user has already stated an API mode preference this session ("custom API" or "native"), skip to Step 3 — do not ask again.

### Step 2: Check for Custom API Config

Read these files in order (first `planExecution` key found wins):
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

**If config found** — ask the user:

> "Custom API config found (`<model>` via `<baseUrl>`). Which API should I use this session?
> - **Custom API** — task execution uses the configured endpoint
> - **Native** — use current session model (default)"

**If no config found** — proceed silently with native mode. Do not prompt.

### Step 3: Proceed with the User's Request

Continue with whatever the user originally asked for. The API mode is now set for the session.

## Notes

- This skill sets the preference but does not change the current session's API connection. The custom API is applied by `executing-plans` when it dispatches task subprocesses.
- If invoked via `/switch-api`, override any prior session choice with the new answer.
