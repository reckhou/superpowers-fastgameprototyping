---
description: "Manually switch the API mode for this session (custom endpoint or native Claude)"
---

Override any prior API mode choice with the new answer.

## IMPORTANT: The config file is `settings.json`, NOT `config.json`

Claude Code stores configuration in `settings.json` (not `config.json`). You MUST use the exact filenames below. Do NOT search for or read `config.json` — that file does not exist.

## Step 1: Read config files

Use the Read tool to check these exact paths in order. Stop at the first file that contains a `planExecution` key:

1. **Project config**: Read the file `.claude/settings.json` in the current project root
2. **Global config (Windows)**: Run `echo "$USERPROFILE"` in Bash, then Read `<result>/.claude/settings.json`
3. **Global config (macOS/Linux)**: Read `~/.claude/settings.json`

## Step 2: Ask the user

**If a `planExecution` key was found**, ask:

> "Which API should I use for the rest of this session?
> - **Custom API** — task execution uses the configured endpoint (`<model>` via `<baseUrl>`)
> - **Native** — use current session model (default)"

**If none of the files above exist or none contain a `planExecution` key**, say:

> "No custom API config found. Add a `planExecution` key to `.claude/settings.json` to enable a custom endpoint."

## Step 3: Confirm and continue

After the user answers, confirm the new mode and continue.
