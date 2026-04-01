---
name: sessions
description: "List, resume, archive, or restore saved design/research sessions for the current project. Use to see available sessions or pick up where you left off."
---

# Sessions

Manage saved design and research sessions for the current project. Sessions are markdown files stored in the project's auto-memory under `sessions/`.

---

## Determining the Memory Path

- Run `echo "$USERPROFILE"` to get the home directory
- The project key is derived from the current working directory: replace path separators with `--` and remove colons (e.g. `E:\ClaudeCode\AXIOM` → `E--ClaudeCode--AXIOM`)
- Memory path: `<USERPROFILE>\.claude\projects\<project-key>\memory\`
- Sessions directory: `<memory-path>/sessions/`

---

## Sub-commands

### List (default)

**Triggered by:** `/sessions`, `/sessions list`, "show my sessions", "what sessions do I have"

1. Read the `## Sessions` section from MEMORY.md
2. If no sessions section or it is empty: respond with "No saved sessions for this project."
3. Otherwise display a numbered list:

```
Saved sessions for [project name]:

1. Architecture Brainstorm (2026-04-01) — paused at task 3/7
2. Inventory System (2026-03-28) — brainstorm complete, plan written

Commands: "resume 1", "archive 2", "show 1" (full details)
```

If there are more than 30 active sessions, append:
> "You have [N] active sessions — consider archiving completed ones with `/sessions archive`."

---

### Resume

**Triggered by:** "resume 1", "resume Architecture Brainstorm", `/sessions resume <name-or-number>`

1. Identify the session from the number or name match in the MEMORY.md sessions list
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

4. The session context is now loaded — use it to inform all subsequent responses in this conversation
5. Note internally that this session is "active" — if the user later runs `/save-session`, update this session rather than creating a new one

---

### Archive

**Triggered by:** "archive 2", `/sessions archive <name-or-number>`, `/sessions archive` (interactive)

1. If no argument: show the session list and ask which to archive
2. Move the session file from `sessions/` to `sessions/archive/` (create the archive directory if it doesn't exist)
3. Remove the entry from the `## Sessions` section of MEMORY.md
4. Confirm:
   > "Archived '[title]'. It's still in `sessions/archive/` if you need it later."

---

### Restore

**Triggered by:** "restore [name]", `/sessions restore <name>`

1. If no name given: list files in `sessions/archive/`
2. Move the file back from `sessions/archive/` to `sessions/`
3. Re-add the entry to the `## Sessions` section of MEMORY.md
4. Confirm:
   > "Restored '[title]' to active sessions."

---

### Show

**Triggered by:** "show 1", `/sessions show <name-or-number>`

1. Identify the session from the number or name match
2. Read and display the full session file content so the user can review it without resuming

---

## Verify

- **List:** Shows numbered entries from MEMORY.md sessions section
- **Resume:** Loads full session context and presents summary
- **Archive:** Moves file to `sessions/archive/` and removes MEMORY.md entry
- **Restore:** Moves file back to `sessions/` and re-adds MEMORY.md entry
- **Show:** Displays full session file without changing state
