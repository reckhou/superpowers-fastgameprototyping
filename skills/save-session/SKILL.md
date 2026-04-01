---
name: save-session
description: "Save current session context (goal, decisions, status, highlights) to a resumable session file in project memory. Use at the end of design/research sessions or when brainstorming prompts you to save."
---

# Save Session

Capture the current conversation's context into a resumable markdown file stored in the project's auto-memory, so future conversations can pick up where you left off.

---

## Step 1: Check Opt-in Status

Determine the project memory path:
- Run `echo "$USERPROFILE"` to get the home directory
- The project key is derived from the current working directory: replace path separators with `--` and remove colons (e.g. `E:\ClaudeCode\AXIOM` → `E--ClaudeCode--AXIOM`)
- Memory path: `<USERPROFILE>\.claude\projects\<project-key>\memory\`

Check if `project_sessions_enabled.md` exists in that memory directory.

**If it does not exist:**

Ask the user:
> "This project doesn't have session saving enabled yet. Would you like to opt in? (Sessions are saved as markdown files in your project memory — lightweight and version-controllable.)"

- **If yes:** Create `project_sessions_enabled.md`:
  ```markdown
  ---
  name: Session persistence enabled
  description: This project has opted into the session persistence system
  type: project
  ---
  
  Session persistence is enabled for this project.
  Opted in: [current date]
  ```
  Also create the `sessions/` subdirectory in the memory folder.
  Add a `## Sessions` heading at the bottom of `MEMORY.md` (if not already present).

- **If no:** Create `project_sessions_enabled.md` with `enabled: false` in the body so the user is not asked again. Do not proceed with the save.

**If it exists and contains `enabled: false`:** Do not proceed, do not ask again.

---

## Step 2: Gather Session Context

Based on the current conversation, draft a session summary and present it to the user for confirmation. Format it like this:

```
Session summary I'll save:

**Title:** [descriptive name, e.g. "AXIOM Architecture Brainstorm"]
**Goal:** [what this session was about]

**Key Decisions:**
- [decision 1]
- [decision 2]

**Current Status:** [where things stand]
**Next Steps:** [what to do when resuming]

**Open Questions:**
- [question 1]

**Plan Reference:** [path to plan file, if any — or "None"]

**Conversation Highlights:**
- [key insight or exchange 1]
- [key insight or exchange 2]

Shall I save this, or would you like to adjust anything?
```

**Do NOT save without user confirmation.** The user may want to add, remove, or rephrase items.

---

## Step 3: Write the Session File

**Filename format:** `YYYY-MM-DDTHHMM-<title-slug>.md`
- Title slug is lowercase kebab-case derived from the session title
- Example: `2026-04-01T1430-axiom-architecture-brainstorm.md`

**File location:** `<project-memory>/sessions/`

**File format:**

```markdown
---
name: [Session title]
created: [YYYY-MM-DDTHH:MM]
updated: [YYYY-MM-DDTHH:MM]
project: [project name derived from working directory]
status: paused
---

## Goal
[Goal text]

## Key Decisions
- [decision 1]
- [decision 2]

## Current Status
[Status text]

## Next Steps
[What to do when resuming]

## Open Questions
- [question 1]

## Plan Reference
[path to plan file, or "None"]

## Conversation Highlights
- [highlight 1]
- [highlight 2]
```

**Size guardrail:** Target 50–350 lines. If the generated file would exceed 500 lines, warn the user and ask which sections to condense. This is a briefing document, not a transcript.

---

## Step 4: Update MEMORY.md

Add or update an entry under the `## Sessions` heading in MEMORY.md:

```markdown
- [Session Title](sessions/YYYY-MM-DDTHHMM-title-slug.md) — [one-line status summary]
```

- If updating an existing session (same title, re-saved after resuming): replace the old entry rather than adding a duplicate. Rename the old session file to the new timestamp.
- If the `## Sessions` heading does not exist, append it at the bottom of MEMORY.md.

---

## Step 5: Confirm

Tell the user:
> "Session saved to `<path>`. You can resume it in a future session by saying 'resume [title]' or running `/sessions`."

---

## Verify

- Session file exists at the expected path
- MEMORY.md contains the session entry under `## Sessions`
