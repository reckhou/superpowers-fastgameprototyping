---
name: using-git-worktrees
description: Use when you want an isolated branch workspace for a feature — optional for prototypes, useful for anything heading toward production
---

# Using Git Worktrees

Create an isolated workspace on its own branch, sharing the same repo. Useful when you want to keep main clean while prototyping.

**For throwaway prototypes:** skip this — just work on a feature branch directly or on main.

**Use worktrees when:** the work is substantial enough that you want branch isolation without losing your current working state.

## Setup

```bash
# Check if worktree directory exists
ls .worktrees 2>/dev/null || ls worktrees 2>/dev/null

# If project-local directory: verify it's gitignored
git check-ignore -q .worktrees || echo "Add .worktrees to .gitignore first"

# Create worktree on a new branch
git worktree add .worktrees/<branch-name> -b <branch-name>
cd .worktrees/<branch-name>
```

Run project setup if needed (dotnet restore, godot import, etc.).

## Cleanup

After finishing, invoke `finishing-a-development-branch` which handles merge/PR/discard and worktree removal.

## Quick Reference

| Situation | Action |
|---|---|
| Throwaway prototype | Skip worktrees, work on a branch or main |
| Substantial feature | Use `.worktrees/<name>` |
| Directory not gitignored | Add to `.gitignore` before creating |
| Tests fail on baseline | Report and ask whether to proceed |
