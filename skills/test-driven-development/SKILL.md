---
name: test-driven-development
description: Use when implementing logic, systems, or bugfixes where automated testing is practical
---

# Test-Driven Development

Write the test first, watch it fail, write minimal code to pass it.

**Core principle:** If you didn't see the test fail, you don't know if it tests the right thing.

## When TDD Applies

**Use TDD for:**
- Game logic (damage calculation, state machines, inventory systems, rules)
- Data parsing and serialization (save/load, asset formats)
- WPF viewmodels and commands
- Utility systems (pathfinding, AI behaviour, math helpers)
- Bug fixes — write a failing test reproducing the bug first

**Skip TDD for:**
- Visual/rendering output (shaders, particle effects, UI layout feel)
- Physics feel and tuning
- Godot scene setup and node wiring
- Throwaway prototype spikes you'll delete
- Generated or config-only code

When unsure: if you can write an assertion without running the game, TDD applies.

## Red-Green-Refactor

**RED** — Write one minimal failing test for the behaviour you want.

```csharp
[Test]
public void TakeDamage_ReducesHealth()
{
    var player = new Player(maxHealth: 100);
    player.TakeDamage(30);
    Assert.AreEqual(70, player.Health);
}
```

**Verify RED** — Run the test. Confirm it fails because the feature is missing, not due to a syntax error.

**GREEN** — Write the simplest code that makes it pass. No extras.

**Verify GREEN** — Run the test. Confirm it passes and nothing else broke.

**REFACTOR** — Clean up while tests stay green. Extract duplication, improve names.

Repeat for the next behaviour.

## Rules

- One test at a time
- Minimal code to pass — no speculative features
- Watch it fail before writing code
- All tests pass before moving on

## C# / Godot Test Setup

**C# with NUnit (Godot or .NET):**
```bash
dotnet test
dotnet test --filter "TestName"
```

**GDScript with GUT:**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

## When Stuck

| Problem | Solution |
|---|---|
| Don't know how to test it | Write the wished-for API first, assertion second |
| Test setup is enormous | The design is too coupled — simplify |
| Must mock everything | Use dependency injection |
| It's visual/physics | Skip TDD, verify manually in-engine |
