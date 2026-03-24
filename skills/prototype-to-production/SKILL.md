---
name: prototype-to-production
description: Use when a throwaway prototype has survived and needs to become foundation code — before it grows roots in the wrong direction.
---

# Prototype to Production

A throwaway that survived is a liability. It worked for a spike; it wasn't designed for anything else. This skill turns it into something you can actually build on.

**Goal:** Deliberate promotion — not gradual drift. Make an explicit decision, then restructure properly.

---

## Step 1: Make the Decision Explicitly

Don't drift into production use. Ask:

> "Is this prototype ready to become foundation code, or should we rewrite it properly?"

| Promote (refactor existing code) | Rewrite (start fresh) |
|---|---|
| Core logic is sound, structure is messy | Architecture is fundamentally wrong |
| Saving file format / data structures are correct | Prototype took shortcuts that now compound |
| 30-40% of code would survive anyway | Less than a third is reusable |
| Team understands it well enough to clean it up | Easier to explain from scratch than untangle |

**Default toward rewrite when in doubt.** Refactoring prototype code tends to preserve the original sins.

---

## Step 2: Identify What's Prototype-Grade and What's Not

Go through the prototype code and note:

**Keep as-is (already sound):**
- Core algorithms and game logic
- Data structures that represent the domain correctly
- Any tests that exist

**Needs hardening:**
- Error handling that was skipped
- Nullable references that were assumed safe
- Magic numbers / hardcoded values
- Shared state that was fine for a spike but dangerous long-term

**Needs restructuring:**
- God objects doing too many things
- Tight coupling between systems that should be independent
- Missing interfaces/abstractions that the WPF tool and Godot will both need
- Anything that can't be unit tested because it's entangled with engine types

---

## Step 3: Invoke Brainstorming for the Production Version

Don't just start cleaning up. Run `brainstorming` for the production version:

- Scope: foundation (you've already decided this)
- What does the architecture look like without the prototype constraints?
- What data does the WPF tool need vs. what Godot needs?
- Where does the Core classlib boundary go?

Then write a proper plan (`writing-plans`) for the production version.

---

## Step 4: Execute the Promotion

Two approaches:

### A) Refactor in place
- Write tests first (where applicable) to lock in correct behavior
- Restructure one piece at a time, keeping everything runnable
- Use the plan's verification steps to confirm nothing broke

### B) Rewrite alongside
- Keep prototype running while building the production version
- Migrate behavior piece by piece using tests to validate parity
- Remove prototype once production version passes all parity checks

Both approaches: **never mix prototype and production code in the same class/system once you've decided to promote.** Draw a clear boundary.

---

## Step 5: Remove the Prototype

Once the production version is verified:
- Delete the prototype code
- Don't keep it "just in case" — git history has it
- Update any references (imports, scene references, autoloads)

---

## Signs You're Not Ready to Promote Yet

- You don't know what the production architecture should be
- The prototype is still changing rapidly
- You're promoting because you're tired of the prototype, not because it's ready

In any of these cases: keep prototyping. Promote when the design is stable, not when you're frustrated.

---

## When to Invoke This Skill

- A throwaway prototype survives into a second session (from `brainstorming`)
- You find yourself building on prototype code that "wasn't meant to last"
- A system written as a spike is now being referenced by other systems
- Someone asks "can we just ship this?" and the answer involves cleaning it up first
