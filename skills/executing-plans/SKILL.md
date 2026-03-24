---
name: executing-plans
description: Use when you have a written implementation plan to execute
---

# Executing Plans

## Overview

Load the plan, execute tasks in order, verify each one, move on.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan

1. Read the plan file
2. If anything is unclear or blocked before starting, raise it now
3. Create todos for all tasks, then begin

### Step 2: Execute Each Task

For each task:
1. Mark as `in_progress`
2. Implement per the plan
3. Run the verification step specified in the plan
4. Commit
5. Mark as `completed`
6. Move to next task

### Step 3: Finish Up

After all tasks complete:
- Invoke `finishing-a-development-branch` to merge, push PR, or keep as-is

## When to Stop and Ask

Stop immediately if:
- A blocker prevents starting or continuing a task
- The plan has a gap that can't be worked around
- Verification fails and the cause is unclear

Ask rather than guess.

## Remember

- Follow the plan — don't improvise features not in it
- Verify each task before marking complete
- Commit after each task
- Never implement on main/master without explicit consent
