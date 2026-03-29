---
description: "Manually switch the API mode for this session (custom endpoint or native Claude)"
---

Invoke the `session-config` skill's API selection step immediately, regardless of whether it has already run this session. Override any prior API mode choice with the new answer.

Read these files in order (first `planExecution` key found wins):
1. `.claude/settings.json` in the project root
2. Platform-appropriate global settings:
   - **Windows**: use Bash to run `echo "$USERPROFILE"` to get the home directory, then Read `<result>/.claude/settings.json`
   - **macOS/Linux**: `~/.claude/settings.json`

If a `planExecution` key is found, ask:

> "Which API should I use for the rest of this session?
> - **Custom API** — task execution uses the configured endpoint (`<model>` via `<baseUrl>`)
> - **Native** — use current session model (default)"

If no config is found, inform the user:

> "No custom API config found. Add a `planExecution` key to `.claude/settings.json` to enable a custom endpoint."

After the user answers, confirm the new mode and continue.
