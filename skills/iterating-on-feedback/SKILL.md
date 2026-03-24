---
name: iterating-on-feedback
description: Use after playtesting, user testing, or any feedback session to rapidly triage and implement changes without losing prototype momentum.
---

# Iterating on Feedback

Playtesting gives you a list of things to change. This skill turns that list into fast, targeted changes without derailing the prototype.

**Goal:** Triage what matters, discard what doesn't, implement quickly, playtest again.

---

## Step 1: Capture Feedback

Write down or paste all feedback as-is. Don't filter yet.

Common sources:
- Your own playtest notes ("the jump feels floaty", "I kept dying to the same obstacle")
- Someone else's session observations
- A list of "things that felt wrong"

---

## Step 2: Triage — Impact vs. Effort

Go through each item and categorize:

| Category | Criteria | Action |
|---|---|---|
| **Fix now** | Breaks the prototype loop or blocks testing | Implement immediately |
| **Tweak** | Quick parameter/value change, no code restructure | Implement immediately |
| **Explore** | Interesting but needs a spike to know if it's right | Log it, try it after core fixes |
| **Ignore** | Preference, out of scope, or contradicts the prototype goal | Discard explicitly |

**Be ruthless with "Ignore".** Prototypes die from feature creep disguised as feedback.

---

## Step 3: Implement

### For "Fix now" and "Tweak" items:

These are inline changes — no plan needed unless there are 3+ related fixes that touch the same system.

- Make the change
- Verify it in isolation (run game, check the specific behavior)
- Commit: `[iteration] fix: <what changed>`
- Move to the next item

### For "Explore" items:

Treat as a throwaway spike (see `brainstorming` throwaway path):
- Try it quickly
- If it works, keep it; if not, revert
- Don't over-engineer before knowing if the idea is right

### For multiple related changes to the same system:

If 3+ fixes touch the same system, write a quick plan (`writing-plans`) to avoid making a mess. Don't chain ad-hoc changes to a core system without a plan.

---

## Step 4: Playtest Again

After each round of fixes:
- Test the specific behaviors you changed
- Note new feedback
- Repeat from Step 2

Keep iterations short. Aim for: playtest → triage → implement → playtest in under 30 minutes per cycle.

---

## Commit Message Format for Iterations

```
[iteration] <imperative description>

Examples:
[iteration] Reduce jump height from 8 to 6
[iteration] Fix player clipping through thin platforms
[iteration] Increase enemy aggro range to match player speed
```

---

## When to Stop Iterating and Restructure

If the same area keeps breaking across multiple iterations, that's an architecture signal — not a feedback signal. Stop iterating and:
1. Invoke `systematic-debugging` to find the root cause
2. Or invoke `brainstorming` to reconsider the approach

**Don't iterate your way out of an architectural problem.**

---

## When to Invoke This Skill

- After any playtest session
- After receiving a list of "things that felt off"
- When you have a batch of small changes from external feedback
- When the prototype is "mostly working but needs tuning"
