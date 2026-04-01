# Decision Log: Session Persistence System

## Brainstorming Phase — 2026-04-01

### Decision: Scope — Foundation
- **Chosen:** Foundation (shared system, persisted data)
- **Alternatives considered:** Throwaway prototype
- **Rationale:** This system touches every future Claude Code session and shapes how context is built up over time. It must be reliable and well-designed from the start.
- **Trade-offs accepted:** More upfront planning time vs. building quickly and iterating

### Decision: Storage — Integrated into native memory system
- **Chosen:** Sessions stored at `<project-memory>/sessions/`, indexed in MEMORY.md
- **Alternatives considered:** Separate system at `docs/sessions/` with its own INDEX.md; standalone `sessions/` directory outside memory
- **Rationale:** MEMORY.md is auto-loaded every session, making session list immediately visible. Single system to maintain. Project-scoped by default. No new hooks or infrastructure needed.
- **Trade-offs accepted:** MEMORY.md has a 200-line limit — sessions take some of that budget (estimated 1-2 lines per session, well within limits for 30+ sessions)

### Decision: Save trigger — Explicit with skill-driven prompting
- **Chosen:** User explicitly saves via `/save-session`, brainstorming skill prompts "save this session?" at the end
- **Alternatives considered:** Fully automatic save via hooks; `Stop` hook to auto-save every turn; SessionEnd hook (doesn't exist)
- **Rationale:** No `SessionEnd` hook exists in Claude Code. The `Stop` hook fires on every Claude turn (far too noisy). Explicit saves are more reliable and let the user decide what's worth preserving. Brainstorming prompt ensures design sessions aren't forgotten.
- **Trade-offs accepted:** User must remember to save (mitigated by skill prompting)

### Decision: Opt-in via memory flag per project
- **Chosen:** A `project_sessions_enabled.md` file in project memory acts as the opt-in flag. First save attempt triggers opt-in prompt if flag doesn't exist.
- **Alternatives considered:** Global toggle; per-project .claude/settings.json entry; always enabled
- **Rationale:** Project memory is the natural place for project-scoped state. No global config to manage. User is asked once per project, answer is remembered. Follows existing memory-file-as-config pattern.
- **Trade-offs accepted:** One extra file per opted-in project

### Decision: No delete — archive only
- **Chosen:** Sessions can be archived (moved to `sessions/archive/`, removed from MEMORY.md) but never deleted by the skill. Manual deletion via filesystem/git is always available.
- **Alternatives considered:** Delete command in the skill; auto-delete after 90 days
- **Rationale:** The cost of keeping a small markdown file is zero. The cost of accidentally losing context you need months later is high. Git provides the ultimate safety net, but archive-first means you don't even need to dig through history.
- **Trade-offs accepted:** Archive directory may accumulate files over time (negligible storage cost)

### Decision: Session file size — soft target 50-150 lines, warn at 200
- **Chosen:** Soft target of 50-150 lines per session file, warning (not hard block) at 200 lines
- **Alternatives considered:** Hard cap at 200 lines; no limit; cap at 100 lines
- **Rationale:** Session files are briefing documents, not transcripts. 50-150 covers all sections comfortably. 200-line warning is a "pause and compress" trigger, not a hard ceiling. Complex sessions may legitimately need 250 lines.
- **Trade-offs accepted:** Relies on save-session skill being good at summarising rather than enforcing a hard cutoff

### Decision: Active session warning at 30+
- **Chosen:** Soft suggestion to review/archive when active sessions exceed 30
- **Alternatives considered:** Warning at 10 (too restrictive); no warning; warning at 50
- **Rationale:** User expects to have 20-30 active sessions routinely. Warning at 30 catches genuine accumulation without being annoying. The real limit is MEMORY.md readability, not storage.
- **Trade-offs accepted:** MEMORY.md could have 30+ session lines (60+ characters each) — still well within 200-line limit when combined with other memory entries

### Decision: MCP profile — out of scope
- **Chosen:** MCP server management is not coupled to the session system
- **Alternatives considered:** Session files include an `mcp_profile` field that suggests which servers to enable/disable on resume
- **Rationale:** MCP configuration is resolved before Claude launches (settings.json, env vars). By the time a session file is read, MCP overhead is already paid. The right layer for MCP control is per-project settings.json and cloud connector env vars, not session files.
- **Trade-offs accepted:** Users must manage MCP configuration separately from session management

## Planning Phase — 2026-04-01

### Decision: Two skills (save-session + sessions) rather than one combined skill
- **Chosen:** Separate `/save-session` for writing and `/sessions` for listing/resuming/archiving
- **Alternatives considered:** Single `/sessions` skill handling all operations including save; three separate skills (save, list, resume)
- **Rationale:** Separation of concerns — saving is a write operation with a confirmation flow; listing/resuming/archiving is a read/management operation. Two skills keeps each focused. The brainstorming skill can invoke `save-session` directly without loading management logic.
- **Trade-offs accepted:** Two skill files to maintain instead of one

### Decision: Brainstorming skill prompts for save, doesn't auto-save
- **Chosen:** Brainstorming asks "save this session?" after user confirms direction, before invoking writing-plans
- **Alternatives considered:** Auto-save every brainstorm; save only on explicit user request; save after plan is written
- **Rationale:** Not every brainstorm is worth saving (quick throwaway spikes). Prompting at the natural pause point (user confirmed, about to write plan) catches the right moment without being presumptuous.
- **Trade-offs accepted:** One extra confirmation step in the brainstorming flow
