---
description: "Manually switch the API mode for this session (custom endpoint or native Claude)"
---

Override any prior API mode choice with the new answer.

> **Scope**: This setting only affects task subprocesses dispatched by `executing-plans` (Path B). It does NOT change the main session model or affect any other skill.

## IMPORTANT: The config file is `settings.json`, NOT `config.json`

Claude Code stores configuration in `settings.json` (not `config.json`). You MUST use the exact filenames below. Do NOT search for or read `config.json` — that file does not exist.

## Step 1: Read config files

Use the Read tool to check these exact paths in order. Stop at the first file that contains a `planExecution` key:

1. **Project config**: Read the file `.claude/settings.json` in the current project root
2. **Global config (Windows)**: Run `echo "$USERPROFILE"` in Bash, then Read `<result>/.claude/settings.json`
3. **Global config (macOS/Linux)**: Read `~/.claude/settings.json`

## Step 2: Ask the user

**If a `planExecution` key was found**, present an interactive choice:

> "Custom API config found (`<model>` via `<baseUrl>`). Which API should I use for task execution this session?
>
> 1. **Custom API** — `executing-plans` subprocesses use the configured endpoint
> 2. **Native** — inline execution with the current session model (default)
>
> Note: this only affects task subprocesses — it does NOT change the current conversation model.
>
> Reply with 1 or 2."

**If none of the files exist or none contain a `planExecution` key**, say:

> "No custom API config found. Add a `planExecution` key to `.claude/settings.json` to enable a custom endpoint for `executing-plans` task subprocesses."

## Step 3: Confirm and continue

After the user answers, confirm the new mode and continue.
