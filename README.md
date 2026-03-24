# Superpowers — Fast Prototype Edition

A fork of [obra/superpowers](https://github.com/obra/superpowers) tuned for **fast game prototyping** — lightweight game projects, .NET WPF game toolsets written in C#, and Godot games (GDScript and C#).

The original Superpowers is a disciplined, production-grade workflow plugin. This fork keeps the parts that matter for rapid iteration and strips out the ceremony that kills prototype momentum.

---

## What's Different From the Original

### Removed / Gutted

| Original | This Fork |
|---|---|
| Full brainstorming dialog — socratic questions, written spec, spec review loop | Quick spike brief — one exchange, then write code |
| Mandatory git worktrees before any work | Optional — skip for throwaway prototypes |
| Subagent-driven development as the recommended path (fresh subagent + two-stage review per task) | `executing-plans` is the default — inline, no overhead |
| Plan document reviewer subagent | Gone |
| Per-task spec compliance + code quality review loops | Gone |
| TDD iron law — no production code without a failing test, no exceptions | TDD scoped to logic/systems — explicitly skipped for visual, physics, scene setup |
| `writing-skills` meta skill | Removed |
| Task granularity: 2-5 minutes | Task granularity: 15-30 minutes |

### Added

| Skill | Purpose |
|---|---|
| **`godot-workflow`** | GDScript and C# patterns, scene/node architecture, signals, resources, testing (GUT/GdUnit4Net), Godot CLI |
| **`dotnet-csharp-workflow`** | dotnet CLI, solution structure, NuGet/CPM, MSBuild, nullable types, modern C# features, Godot .csproj setup |
| **`wpf-toolset-patterns`** | MVVM with CommunityToolkit.Mvvm, data binding, property inspector, tile map canvas, scene tree, undo/redo, file I/O, WPF-to-Godot data bridge |
| **`iterating-on-feedback`** | Triage and rapid iteration after playtesting — fix/tweak/explore/ignore classification, iteration commit format |
| **`prototype-to-production`** | Deliberate promotion of throwaway code to foundation — promote vs. rewrite decision, code audit, rewrite-alongside pattern |

### Modified

| Skill | Change |
|---|---|
| **`brainstorming`** | Always asks throwaway-vs-foundation (never self-determines). Multi-approach proposals with reasoning for tech decisions. Opt-out confirmation before planning. |
| **`writing-plans`** | Gates on brainstorming first. Kebab-case file naming enforced. Architecture field requires headless testability statement. Plan format includes Progress checkboxes for cross-session resume. Scope expansion must be surfaced. |
| **`executing-plans`** | Invokes `writing-plans` if no plan file exists. Plan-referenced commit format (`[plan: feature-name, task-N]`). Conventional commits when no plan. Resume trusts prior completion via plan file checkboxes. |
| **`systematic-debugging`** | Replaced macOS codesign CI example with Godot/C# signal-tracing example. Phase 4 Step 1 adds visual/physics exception — document reproduction steps instead of failing test. |
| **`using-superpowers`** | Announces active skill before following it. Bug fast-path — if user reports a bug, invoke `systematic-debugging` directly, skip brainstorming. Workflow sequence flowchart added. |
| **`godot-workflow`** | Game exports target Windows/Mac/Linux. WPF toolset is Windows-only dev toolset, not part of game build. |
| **`test-driven-development`** | Added explicit skip list: visual/rendering output, physics feel, Godot scene wiring, throwaway spikes |

---

## How It Works

Skills are markdown files that tell Claude *how* to approach a task. A SessionStart hook bootstraps the skill system at the start of every session. Claude checks for applicable skills before taking any action, **announces which skill it's using**, and follows it automatically — you don't invoke skills manually.

### The Fast Prototype Flow

```
You describe what to build
        ↓
brainstorming  →  Asks: throwaway or foundation?
                  Throwaway: just build.
                  Foundation: propose approach (with reasoning), confirm, then plan.
        ↓
writing-plans  →  Task breakdown saved to docs/plans/YYYY-MM-DD-feature-name.md
                  (15-30 min tasks, progress checkboxes for resume)
        ↓
executing-plans →  Implement each task inline, verify, commit, check off in plan
        ↓
finishing-a-development-branch  →  Merge / push PR / keep / discard
```

Interrupts that can happen at any point:
- **Report a bug** → `systematic-debugging` kicks in directly (skips brainstorming)
- **After playtesting** → `iterating-on-feedback` triages changes
- **Throwaway survived** → `prototype-to-production` promotes it properly
- Writing game logic or a viewmodel → `test-driven-development` applies
- Working in Godot → `godot-workflow` guides architecture and pattern choices
- Working on a WPF toolset → `wpf-toolset-patterns` guides MVVM, canvas, undo/redo

---

## Installation

### Claude Code (Direct from GitHub)

```bash
/plugin install github:reckhou/superpowers
```

Or clone and install from local path:

```bash
git clone https://github.com/reckhou/superpowers path/to/superpowers
/plugin install path/to/superpowers
```

### Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/reckhou/superpowers
   ```

2. In your Claude Code settings (`~/.claude/settings.json`), add the plugin path:
   ```json
   {
     "plugins": ["path/to/superpowers"]
   }
   ```

3. Start a new session. The SessionStart hook will bootstrap the skill system automatically.

### Verify Installation

Start a new session and ask Claude to build something. It should announce `Using superpowers:brainstorming`, ask whether the work is throwaway or foundation, then proceed accordingly.

Or explicitly check: ask Claude *"what skills do you have available?"* — it should list the superpowers skills.

### Updating

```bash
cd path/to/superpowers
git pull
```

Restart your Claude Code session to pick up changes.

---

## Skills Reference

### Domain Skills (New in This Fork)

| Skill | Triggers when |
|---|---|
| `godot-workflow` | Working on any Godot project — scenes, scripts, signals, testing, CLI |
| `dotnet-csharp-workflow` | Working on .NET/C# — solution setup, build, test, NuGet, Godot .csproj |
| `wpf-toolset-patterns` | Building a WPF game editor or toolset |

### Core Workflow Skills (Modified)

| Skill | What it does |
|---|---|
| `brainstorming` | Always asks throwaway/foundation → propose approach with reasoning → invoke writing-plans |
| `writing-plans` | Task breakdown (15-30 min tasks) → progress checkboxes → saved to `docs/plans/` |
| `executing-plans` | Primary execution path — inline, task by task, verify, commit, check off in plan |
| `finishing-a-development-branch` | Merge / push PR / keep / discard + cleanup |
| `iterating-on-feedback` | Triage playtest feedback → fix/tweak/explore/ignore → rapid iteration loop |
| `prototype-to-production` | Promote a surviving throwaway to foundation code deliberately |

### Discipline Skills (Kept, Trimmed)

| Skill | What it does |
|---|---|
| `systematic-debugging` | 4-phase root cause investigation before any fix — invoked directly on bug reports |
| `verification-before-completion` | Run the command, read the output, then claim success |
| `test-driven-development` | RED-GREEN-REFACTOR for logic and systems (not visual/physics) |
| `requesting-code-review` | On-demand code review via subagent |
| `receiving-code-review` | How to handle review feedback |
| `dispatching-parallel-agents` | Parallel independent task delegation |

### Optional / Heavy (Use When Warranted)

| Skill | When to use |
|---|---|
| `subagent-driven-development` | Large independent tasks that benefit from context isolation |
| `using-git-worktrees` | Substantial features where branch isolation matters |

---

## Project Structure

```
superpowers/
├── .claude-plugin/plugin.json       # Claude Code manifest
├── hooks/
│   ├── hooks.json                   # Claude Code SessionStart hook
│   └── session-start                # Bootstrap script
├── skills/
│   ├── brainstorming/               # Modified: always ask scope, reasoning, opt-out confirm
│   ├── dotnet-csharp-workflow/      # New: .NET/C# tooling
│   ├── godot-workflow/              # New: Godot GDScript + C# (game: Win/Mac/Linux)
│   ├── wpf-toolset-patterns/        # New: WPF game editors (Windows-only toolset)
│   ├── iterating-on-feedback/       # New: post-playtest iteration loop
│   ├── prototype-to-production/     # New: promote throwaway to foundation
│   ├── executing-plans/             # Modified: plan-ref commits, resume via checkboxes
│   ├── writing-plans/               # Modified: brainstorm gate, headless testability, progress section
│   ├── test-driven-development/     # Modified: logic only, not visual/physics
│   ├── systematic-debugging/        # Modified: Godot/C# examples, visual/physics exception
│   ├── verification-before-completion/
│   ├── subagent-driven-development/ # Modified: optional, no mandatory reviews
│   ├── using-git-worktrees/         # Modified: optional for prototypes
│   ├── requesting-code-review/
│   ├── receiving-code-review/
│   ├── dispatching-parallel-agents/
│   ├── finishing-a-development-branch/
│   └── using-superpowers/           # Modified: announce skill, bug fast-path, workflow flowchart
├── agents/
│   └── code-reviewer.md
└── commands/                        # Deprecated upstream commands
```

---

## Original Superpowers

This fork is based on [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent. If you want the full production-grade workflow with mandatory TDD, spec reviews, and subagent-driven development, use the original.

If Superpowers has helped Jesse's work help yours, consider [sponsoring him](https://github.com/sponsors/obra).

---

## License

MIT — see LICENSE file.
