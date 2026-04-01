# Session Persistence System — Implementation Plan

**Goal:** Enable Claude Code to save, list, resume, and archive design/research session context so that future conversations can pick up where they left off — like Claude Projects but running entirely in Claude Code's memory system.

**Architecture:** Sessions are markdown files stored in the project's auto-memory directory under `sessions/`. MEMORY.md (auto-loaded every session) contains a small "Sessions" section with one-line pointers. Resuming loads the full session file into context. The brainstorming skill is updated to prompt for save at the end. Two new skills (`save-session`, `sessions`) handle all CRUD operations. An opt-in flag (`project_sessions_enabled.md`) in the project memory controls whether session features are active.

**Tech Stack:** Claude Code skills (SKILL.md markdown files), project auto-memory (markdown files with frontmatter)

---

## Progress

- [x] Task 1: Create the `save-session` skill
- [x] Task 2: Create the `sessions` skill (list, resume, archive, restore)
- [x] Task 3: Update `brainstorming` skill to prompt for session save + opt-in flow

---

## Files

- Create: `skills/save-session/SKILL.md` — skill that captures current session context and writes a session file + updates MEMORY.md
- Create: `skills/sessions/SKILL.md` — skill that lists, resumes, archives, and restores saved sessions
- Modify: `skills/brainstorming/SKILL.md` — add post-brainstorm prompt to save session + opt-in check
- Modify: `skills/using-superpowers/SKILL.md` — register new skills in the skill catalogue

---

### Task 1: Create the `save-session` skill

**Files:** `skills/save-session/SKILL.md`

Create the skill at `E:\ClaudeCode\Superpower-FastPrototype\skills\save-session\SKILL.md`.

**Frontmatter:**

```yaml
---
name: save-session
description: "Save current session context (goal, decisions, status, highlights) to a resumable session file in project memory. Use at the end of design/research sessions or when brainstorming prompts you to save."
---
```

**Skill behaviour — step by step:**

#### Step 1: Check opt-in status

Read the project memory directory for `project_sessions_enabled.md`.
- Memory path is determined by the project's auto-memory location (e.g., `C:\Users\sshan\.claude\projects\<project>\memory\`).
- Use Bash: `echo "$USERPROFILE"` to get the home directory, then construct the memory path from the current working directory.
- The project key is derived from the working directory path with path separators replaced by `--` and colons removed (e.g., `E:\ClaudeCode\AXIOM` becomes `E--ClaudeCode--AXIOM`).

If the file does not exist:
- Ask: "This project doesn't have session saving enabled yet. Would you like to opt in? (Sessions are saved as markdown files in your project memory — lightweight and version-controllable.)"
- If yes: create `project_sessions_enabled.md` with:
  ```markdown
  ---
  name: Session persistence enabled
  description: This project has opted into the session persistence system
  type: project
  ---
  
  Session persistence is enabled for this project.
  Opted in: [current date]
  ```
- Also create the `sessions/` subdirectory in the memory folder.
- Update MEMORY.md to add a `## Sessions` heading at the bottom (if not already present).
- If no: create `project_sessions_enabled.md` with `enabled: false` in the body so the user is not asked again. Do not proceed with save.

If the file exists and says `enabled: false`: do not proceed, do not ask again.

#### Step 2: Gather session context

Ask the user to confirm or refine the following — present your best guess based on the conversation, then let them edit:

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

**Plan Reference:** [path to plan file, if any]

**Conversation Highlights:**
- [key insight or exchange 1]
- [key insight or exchange 2]

Shall I save this, or would you like to adjust anything?
```

Do NOT save without user confirmation. The user may want to add, remove, or rephrase items.

#### Step 3: Write the session file

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

#### Step 4: Update MEMORY.md

Add or update an entry under the `## Sessions` heading in MEMORY.md:

```markdown
- [Session Title](sessions/YYYY-MM-DDTHHMM-title-slug.md) — [one-line status summary]
```

If this is an update to an existing session (same title, being re-saved after resuming), replace the old entry rather than adding a duplicate. Also rename the old session file to the new timestamp.

#### Step 5: Confirm

Tell the user: "Session saved to `<path>`. You can resume it in a future session by saying 'resume [title]' or running `/sessions`."

**Size guardrail:** If the generated session file exceeds 500 lines, warn the user and ask which sections can be condensed. Target 50-350 lines. The session file is a briefing document, not a transcript.

**Verify:** Session file exists at the expected path, MEMORY.md contains the session entry.

---

### Task 2: Create the `sessions` skill (list, resume, archive, restore)

**Files:** `skills/sessions/SKILL.md`

Create the skill at `E:\ClaudeCode\Superpower-FastPrototype\skills\sessions\SKILL.md`.

**Frontmatter:**

```yaml
---
name: sessions
description: "List, resume, archive, or restore saved design/research sessions for the current project. Use to see available sessions or pick up where you left off."
---
```

**Skill behaviour — the skill handles four sub-commands based on user intent:**

#### Sub-command: List (default)

Triggered by: `/sessions`, `/sessions list`, "show my sessions", "what sessions do I have"

1. Read the `## Sessions` section from MEMORY.md
2. If no sessions section or empty: "No saved sessions for this project."
3. Otherwise, display a numbered list:

```
Saved sessions for [project name]:

1. Architecture Brainstorm (2026-04-01) — paused at task 3/7
2. Inventory System (2026-03-28) — brainstorm complete, plan written

Commands: "resume 1", "archive 2", "show 1" (full details)
```

If there are more than 30 active sessions, append a soft suggestion:
"You have [N] active sessions — consider archiving completed ones with `/sessions archive`."

#### Sub-command: Resume

Triggered by: "resume 1", "resume Architecture Brainstorm", `/sessions resume <name-or-number>`

1. Identify the session from the number or name match
2. Read the full session file from `<project-memory>/sessions/`
3. Present a brief summary to the user:

```
Resuming: Architecture Brainstorm
Last updated: 2026-04-01

Goal: [goal]
Status: [status]
Next steps: [next steps]
Open questions: [questions]

Ready to continue. What would you like to work on?
```

4. The session context is now loaded — Claude should use it to inform all subsequent responses in this conversation
5. Note internally that this session is "active" — when the user later runs `/save-session`, update this session rather than creating a new one

#### Sub-command: Archive

Triggered by: "archive 2", `/sessions archive <name-or-number>`, `/sessions archive` (interactive)

1. If no argument: show the list and ask which to archive
2. Move the session file from `sessions/` to `sessions/archive/` (create the archive directory if needed)
3. Remove the entry from the `## Sessions` section of MEMORY.md
4. Confirm: "Archived '[title]'. It's still in `sessions/archive/` if you need it later."

#### Sub-command: Restore

Triggered by: "restore [name]", `/sessions restore <name>`

1. List files in `sessions/archive/` if no name given
2. Move the file back from `sessions/archive/` to `sessions/`
3. Re-add the entry to the `## Sessions` section of MEMORY.md
4. Confirm: "Restored '[title]' to active sessions."

#### Sub-command: Show

Triggered by: "show 1", `/sessions show <name-or-number>`

1. Read and display the full session file content so the user can review it without resuming

**Verify:** Each sub-command produces the expected output. List shows numbered entries. Resume loads context. Archive moves file and updates MEMORY.md. Restore reverses archive.

---

### Task 3: Update `brainstorming` skill to prompt for session save + opt-in flow

**Files:** `skills/brainstorming/SKILL.md`, `skills/using-superpowers/SKILL.md`

**Depends on:** Task 1, Task 2

#### Brainstorming skill update

Add a new section at the very end of `skills/brainstorming/SKILL.md`, after the "Decision Log" section and before any closing content:

```markdown
## Session Save Prompt

After the user confirms direction and the decision log is written, ask:

> "Would you like to save this brainstorming session so you can resume it later? (Say yes to run `/save-session`, or skip if this is a quick throwaway.)"

This prompt should appear:
- After every brainstorming session that reaches the "user confirms direction" stage
- Before invoking `writing-plans`

If the user says yes, invoke the `save-session` skill. If no, proceed directly to `writing-plans` (or end, depending on user intent).

If the project hasn't opted into sessions yet, the `save-session` skill will handle the opt-in prompt — don't duplicate that check here.
```

#### Using-superpowers skill update

Add the two new skills to the skill catalogue in `skills/using-superpowers/SKILL.md`:

- `save-session` — in the "Interrupts that can happen at any point" section or equivalent
- `sessions` — in the same section

These should be listed as available skills so Claude knows to invoke them when relevant.

**Verify:** After updating, read the brainstorming skill and confirm the session save prompt appears at the end. Read using-superpowers and confirm both new skills are listed.
