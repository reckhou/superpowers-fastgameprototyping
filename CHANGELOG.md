# Changelog

## [5.5.1] - 2026-05-14

### Fixed

- **Codex CLI installer target directory**: 5.5.0's `scripts/codex-install.ps1` symlinked files into `~/.codex/prompts/` on the assumption that Codex would surface them as bare `/<name>` slash commands. Codex CLI 0.130.0 does not read that directory at all — its slash command set is a hardcoded enum. User-authored extensions live in `$HOME/.agents/skills/` and appear under the `/skills` menu.
  - Installer now creates folder symlinks `~/.agents/skills/<skill-name>` → `skills/<skill-name>/` (preserving full skill directory including `references/` and `scripts/`) and file symlinks `~/.agents/skills/<command-name>/SKILL.md` → `commands/<command-name>.md` for flat command files.
  - README updated with the correct invocation syntax (`/skills` menu, `$skill-name` mention, or Codex auto-selection by description).
  - Conflict detection preserved: cross-repo collisions are reported, not silently overwritten.

## [5.5.0] - 2026-05-14

### Added

- **Codex CLI installer (`scripts/codex-install.ps1`)**: Walks `skills/*/SKILL.md` and `commands/*.md`, creating symlinks under `~/.codex/prompts/` so Superpower's skills become invocable as `/use-<skill>` slash commands under OpenAI Codex CLI. Idempotent; conflict-safe — refuses to overwrite existing prompt symlinks owned by another project. Requires Windows Developer Mode.
- **README: Codex CLI installation section**: Documents the installer plus the subset of skills (`subagent-driven-development`, `dispatching-parallel-agents`, plan-mode-dependent parts of `writing-plans` / `executing-plans`) that depend on Claude-specific primitives and degrade under Codex.

## [5.4.4] - 2026-04-03

### Changed

- **brainstorming: ai-generated file tagging**: All `.md` files created during brainstorming (decision logs, research notes, synthesis documents) must include `ai-generated` in their YAML frontmatter `tags`. Applies to files written by Claude and by research subagents.
- **brainstorming: ai-generated context rule (design tasks)**: When reading existing project files during the context glance, files tagged `ai-generated` are treated as unreviewed drafts, not approved decisions. Only their `Sources` section may be used for external references. Content is surfaced to the user as a hypothesis, not a locked-in decision. User confirming "yes" to proceed to `writing-plans` constitutes approval of the current direction.

## [5.4.1] - 2026-04-01

### Changed

- **code-reviewer converted to skill**: Moved `agents/code-reviewer.md` to `skills/code-reviewer/SKILL.md` so it only loads when triggered, instead of always consuming context tokens.
- **Removed deprecated command stubs**: Deleted `commands/brainstorm.md`, `commands/execute-plan.md`, and `commands/write-plan.md` — these were redirect stubs pointing users to the replacement skills.
- **Reorganized docs**: Moved plan documents from `docs/plans/` to `docs/superpowers/plans/`; added `docs/superpowers/decisions/` for ADRs.

## [5.0.5] - 2026-03-17

### Fixed

- **Brainstorm server ESM fix**: Renamed `server.js` → `server.cjs` so the brainstorming server starts correctly on Node.js 22+ where the root `package.json` `"type": "module"` caused `require()` to fail. ([PR #784](https://github.com/obra/superpowers/pull/784) by @sarbojitrana, fixes [#774](https://github.com/obra/superpowers/issues/774), [#780](https://github.com/obra/superpowers/issues/780), [#783](https://github.com/obra/superpowers/issues/783))
- **Brainstorm owner-PID on Windows**: Skip `BRAINSTORM_OWNER_PID` lifecycle monitoring on Windows/MSYS2 where the PID namespace is invisible to Node.js. Prevents the server from self-terminating after 60 seconds. The 30-minute idle timeout remains as the safety net. ([#770](https://github.com/obra/superpowers/issues/770), docs from [PR #768](https://github.com/obra/superpowers/pull/768) by @lucasyhzhu-debug)
- **stop-server.sh reliability**: Verify the server process actually died before reporting success. Waits up to 2 seconds for graceful shutdown, escalates to `SIGKILL`, and reports failure if the process survives. ([#723](https://github.com/obra/superpowers/issues/723))

### Changed

- **Execution handoff**: Restore user choice between subagent-driven-development and executing-plans after plan writing. Subagent-driven is recommended but no longer mandatory. (Reverts `5e51c3e`)
