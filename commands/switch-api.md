---
description: "Manually switch the API mode for this session (custom endpoint or native Claude)"
---

Invoke the `session-config` skill's API selection step immediately, regardless of whether it has already run this session. Override any prior API mode choice with the new answer.

Read `.claude/config.json` (project root) or `~/.claude/config.json` (global) for a `planExecution` key, then ask:

> "Which API should I use for the rest of this session?
> - **Custom API** — task execution uses the configured endpoint (`<model>` via `<baseUrl>`)
> - **Native** — use current session model (default)"

If no config is found, inform the user:

> "No custom API config found. Add a `planExecution` key to `.claude/config.json` to enable a custom endpoint."

After the user answers, confirm the new mode and continue.
