---
name: godot-workflow
description: "Use when working on any Godot 4 project — scene setup, node architecture, scripting decisions, signals, exports, testing, or CLI usage. Covers both GDScript and C#."
---

# Godot Workflow

Patterns and decisions for Godot 4.x game development. Covers GDScript and C#.

For detailed code patterns and full implementations, open `resources/implementation-playbook.md`.

---

## 1. GDScript vs C# — Pick One, Know Why

### Use GDScript when
- Prototyping — no compile step, hot-reload, tighter editor integration
- Scene-local logic that won't be shared with external tools
- **Web export is required** — C# cannot export to Web/WASM. Hard blocker, not a roadmap item.
- You need GDExtension (C/C++ plugins) — C# cannot call them directly

### Use C# when
- Complex systems with shared logic (e.g., shared with a WPF toolset)
- Large codebases that benefit from interfaces, generics, LINQ, access modifiers
- IDE tooling matters — Rider/Visual Studio refactoring, debugger, test runners
- Unit testing pure logic without the Godot runtime

### For this fork (C# + WPF toolset projects)
**Default to C# for systems and logic.** GDScript is acceptable for simple scene scripts.
When mixing: communicate via signals and autoloads only. Don't tightly couple across languages.

### Performance Reality — Non-Obvious
- **Typed GDScript** can be up to 47% faster than untyped in release builds — the VM emits optimized opcodes when types are known. Always type your GDScript.
- **C# is not always faster.** Every engine API call (e.g., `node.Position`) crosses the C#-to-C++ boundary via Variant marshalling. In tight loops, cache these in local variables.
- Use .NET collections (`List<T>`, `Dictionary<K,V>`) for internal C# logic. Only use Godot's `Array`/`Dictionary` when calling engine APIs.

### Platform Support Matrix (Godot 4.4)
| Platform | GDScript | C# |
|---|---|---|
| Desktop (Win/Mac/Linux) | ✅ | ✅ |
| Android | ✅ | Experimental |
| iOS | ✅ | Experimental |
| Web | ✅ | ❌ Not supported |

---

## 2. Node & Scene Architecture

### Core Rule
One scene = one responsibility. Compose from nodes, don't inherit deeply.

```
Player (CharacterBody2D)
  ├── VelocityComponent (Node)
  ├── HealthComponent (Node)
  ├── StateMachine (Node)
  │     ├── IdleState
  │     ├── RunState
  │     └── AttackState
  └── HitboxComponent (Area2D)
```

### When to Split a Scene
- The subtree is reused in multiple places
- It has its own independent lifecycle
- It benefits from independent editing

### Scene Inheritance vs Instancing
- **Inheritance** (`Inherit from` in editor): for variants of a base scene — `FastEnemy` inheriting `BaseEnemy`. Changes to base propagate.
- **Instancing**: for composition — embedding reusable component scenes.
- Avoid inheritance deeper than 2-3 levels.

### Lifecycle Order — Critical
`_init()` → `_enter_tree()` → `_ready()` — children complete `_ready()` **before** parents.
Never assume a parent node is ready inside a child's `_ready()`.

---

## 3. GDScript Patterns

### Always Use Typed GDScript
```gdscript
# Bad — slow, error-prone
var speed = 200
func move(delta):
    position += velocity * delta

# Good — up to 47% faster in release, catches errors at edit time
var speed: float = 200.0
func move(delta: float) -> void:
    position += velocity * delta
```

Type inference with `:=` is fine when the RHS is already typed.

### Key Annotations
| Annotation | Purpose |
|---|---|
| `@export` | Exposes to Inspector, serialized in scene |
| `@export_range(min, max, step)` | Range-constrained number |
| `@export_enum("A","B","C")` | Dropdown in Inspector |
| `@export_group("Name")` | Group exported properties visually |
| `@export_tool_button("Label")` | Inspector button (Godot 4.4+, no plugin needed) |
| `@onready` | Defer init until after `_ready()` |
| `@tool` | Script runs in editor |

### Critical Gotcha: `@onready` + `@export`
**Never combine on the same variable.** `@onready` silently ignores the Inspector value:
```gdscript
@export @onready var label: Label  # WRONG — export value ignored at runtime
@onready var label: Label = $Label  # Correct for internal node refs
@export var health: int = 100       # Correct for designer-facing values
```

### Modern GDScript 4 Syntax
```gdscript
# Signals — emit directly, no string names
signal player_died
player_died.emit()

# await replaces yield
await get_tree().create_timer(1.0).timeout
await some_signal

# Lambdas
var doubled = items.map(func(x): return x * 2)
button.pressed.connect(func(): handle_press())

# Typed arrays and dicts (4.4+)
var items: Array[Item] = []
var inventory: Dictionary[String, int] = {}
```

---

## 4. C# Patterns

### Lifecycle Methods
```csharp
public override void _Ready()          // Grab node refs here (replaces @onready)
public override void _Process(double delta)
public override void _PhysicsProcess(double delta)
public override void _Input(InputEvent @event)
public override void _EnterTree()
public override void _ExitTree()
```

### Export and Node Access
```csharp
[Export] public int Health { get; set; } = 100;
[Export] public PackedScene BulletScene { get; set; }
[Export(PropertyHint.Range, "0,100")] public float Speed { get; set; }

// Cache in _Ready() — GetNode<T> is an interop call
private Sprite2D _sprite;
public override void _Ready() => _sprite = GetNode<Sprite2D>("Sprite2D");

// Null-safe variant
var label = GetNodeOrNull<Label>("UI/Label");
```

### Signals
```csharp
[Signal] public delegate void PlayerDiedEventHandler();
[Signal] public delegate void ItemCollectedEventHandler(string itemId);

// Emit
EmitSignal(SignalName.PlayerDied);

// Connect — use event syntax, type-safe
otherNode.PlayerDied += OnPlayerDied;
otherNode.PlayerDied -= OnPlayerDied;
```

Signal names are **snake_case in GDScript** even if PascalCase in C#:
```gdscript
$CSharpNode.player_died.connect(_on_player_died)
```

### Performance in C#
```csharp
// Bad — each access is a native interop call
public override void _Process(double delta)
{
    Position += velocity * (float)delta; // Position called every frame
}

// Good — cache in local variable
public override void _Process(double delta)
{
    var pos = Position;
    pos += velocity * (float)delta;
    Position = pos;
}
```

### C# Autoload Access
```csharp
public partial class GameManager : Node
{
    public static GameManager Instance { get; private set; }
    public override void _Ready() => Instance = this;
}

// Access anywhere, type-safe
GameManager.Instance.Score += 10;
```

---

## 5. Signals — The Communication Layer

### Local vs Global
- **Direct connection**: parent watching a child, or closely related nodes. Preferred default.
- **Event Bus (Autoload)**: cross-system events where nodes have no natural relationship.

### Event Bus Pattern
```gdscript
# GameEvents.gd — registered as Autoload "GameEvents"
extends Node
signal player_died(player: Player)
signal item_collected(item_id: String)
signal level_completed(score: int)
```
```gdscript
# Emit from anywhere
GameEvents.player_died.emit(self)

# Connect from anywhere
GameEvents.player_died.connect(_on_player_died)
```

### What Belongs on the Event Bus
- Cross-system events (UI reacting to gameplay, audio reacting to physics)
- Events that cross distant branches of the scene tree

### What Does NOT Belong
- Per-frame communication — use direct calls or `_process`
- Tightly related parent-child signals — connect directly
- Everything — overuse makes debugging very hard (no call stack in debugger)

### Signal Performance
Emitting with one connected node is ~3x slower than a direct call. Fine for gameplay events. Don't use signals in tight inner loops (e.g., inside `_physics_process` per bullet).

---

## 6. Autoloads / Singletons

### What Belongs in Autoloads
- GameManager (game state, score, pause)
- EventBus (global signal relay)
- AudioManager (centralized sound playback)
- SaveManager (file I/O)
- SceneManager (scene transitions with loading)

### What Does NOT Belong
- Scene-specific logic
- Node references (freed between scenes)
- Everything — Autoloads are global; overuse creates hidden dependencies

---

## 7. Resource System

### Custom Resources — Use Them
Replace JSON/CSV data files with typed, editor-friendly Custom Resources:
```gdscript
class_name WeaponData extends Resource
@export var name: StringName
@export var damage: int
@export var icon: Texture2D
@export var projectile_scene: PackedScene
```
Create them in the editor: right-click FileSystem → New Resource → select class.

### preload vs load vs Threaded
| | `preload` | `load` | `ResourceLoader.load_threaded_request` |
|---|---|---|---|
| When | Compile time, constant path | Runtime, dynamic path | Background thread |
| Blocks | Editor parses dep | Main thread | No (async) |

```gdscript
const BULLET = preload("res://scenes/bullet.tscn")  # Path must be a literal constant
var scene = load("res://scenes/" + name + ".tscn")  # Dynamic path OK
```

### Critical Rules
- **Always `duplicate()` resources before runtime use** — shared Resource instances mutate the asset for everyone referencing it
- **Always check `ResourceSaver.save()` return value** — silent failures cause data loss
- Use `user://` for save data (writable), `res://` for bundled assets (read-only at runtime)
- `.tres` = text format, VCS-friendly; `.res` = binary, smaller and faster to load

---

## 8. State Machines

### Node-Based FSM (Most Idiomatic)
```
StateMachine (Node)
  ├── IdleState (Node)
  ├── RunState (Node)
  └── AttackState (Node)
```
Each state has `enter()`, `exit()`, `update(delta)`, `physics_update(delta)`, `handle_input(event)`.
StateMachine holds current state and delegates calls. See `resources/implementation-playbook.md` for full code.

### Concurrent Behaviors — Multiple FSMs
For behaviors that run simultaneously (move AND attack), use **multiple independent state machines**:
```
Player
  ├── LocomotionFSM (idle/run/jump)
  └── CombatFSM (unarmed/attacking/stunned)
```
Never try to encode every combination in a single FSM — it explodes in complexity.

---

## 9. Prototyping Shortcuts

### Use These Built-Ins Without Hesitation
- **CSG nodes** (CsgBox3D, etc.) for 3D level blocking — great for layout validation
- **ColorRect / Panel** for 2D UI placeholders
- **CharacterBody2D/3D** + `move_and_slide()` — handles most movement cases
- **AnimationPlayer** — use it early, even in prototypes. Easier to refactor than hardcoded lerps.
- **TileMap** for 2D grid levels — use it early, chunk later

### Build Custom vs Use Built-In
| Problem | Built-in | Go Custom When |
|---|---|---|
| Player movement | `CharacterBody.move_and_slide()` | Complex physics (water, vehicles) |
| Enemy navigation | `NavigationAgent2D/3D` | >200 agents simultaneously |
| State machines | Simple if/match in `_process` | >5 states with complex transitions |
| Saving | Custom Resource + ResourceSaver | Complex relational data |

### TileMap Performance
Large TileMaps degrade FPS as tile count grows. Chunk them — split into regions and load/unload based on camera position. Don't put navigation on a single giant TileMap.

### Prototyping Mindset
GDScript is faster to prototype in (no compile step, hot-reload). Ignore architecture during prototyping — validate game feel first, refactor a proven concept second.

---

## 10. Testing

### What to Test and How
| Code Type | Tool | Notes |
|---|---|---|
| Pure C# logic (no Godot) | **GdUnit4Net** or NUnit | 10x faster, runs without Godot runtime, VS/Rider integration |
| GDScript systems | **GUT** | Headless CLI support |
| Mixed C# + GDScript scenes | **GdUnit4** | Scene runner, mocking, CI XML reports |
| Visual feel, physics tuning | Manual in-engine | Skip automated testing |
| Godot scene wiring | Manual or GdUnit4 scene runner | |

### C# Logic Tests (Fastest)
```bash
dotnet test
dotnet test --filter "FullyQualifiedName~HealthComponent"
```

### GUT Headless (GDScript)
```bash
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit
```

### GdUnit4 Headless
```bash
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd
```

---

## 11. Godot CLI Reference

```bash
# Run project headless and exit
godot --headless --quit

# Run a specific script
godot --headless -s res://tools/generate_map.gd

# Export builds
godot --export-release "Windows Desktop" ./build/game.exe
godot --export-debug "Linux/X11" ./build/game.x86_64

# Import assets without launching editor
godot --headless --import

# C# tests
dotnet test
dotnet test --filter "Category=Unit"
```

---

## 12. Non-Obvious Gotchas

| Gotcha | Detail |
|---|---|
| `@onready` + `@export` conflict | `@onready` silently ignores the exported Inspector value. Never combine. |
| `_ready()` order | Children complete before parents. Never assume parent is ready in child's `_ready()`. |
| `preload` path must be a literal | Cannot be a dynamic string. Use `load()` for computed paths. |
| Resource shared instances | Modifying a Resource at runtime mutates it for all references. Always `duplicate()` first. |
| `ResourceSaver` return value | Always check it — silent save failures lose data. |
| Physics Layers vs Groups | Use Collision Layers/Masks for filtering physics interactions, not `get_nodes_in_group()` in physics callbacks. |
| C# cannot use GDExtensions | C/C++ plugins have no C# bindings. Bridge via a GDScript intermediary if needed. |
| C# no Web export | Hard blocker — not fixable at project level. Decide this before architecture. |
| Signals in inner loops | ~3x cost vs direct calls. Don't emit signals per-bullet in `_physics_process`. |
| Typed array interop across C#/GDScript | `Array[CustomType]` can fail at the boundary. Use untyped `Array` at the border. |

---

## 13. Godot 4.4+ Features Worth Knowing

- **Jolt Physics** — opt-in alternative physics engine, more stable for complex collision. Enable in Project Settings.
- **Embedded game window** — game runs inside the editor. No alt-tab during development.
- **`@export_tool_button`** — adds an Inspector button in `@tool` scripts without a custom plugin.
- **Typed Dictionaries** — `Dictionary[String, int]` now works across GDScript, C#, and C++.
- **2D Physics Interpolation** — smooth visuals even at low physics tick rate. Per-node or global.

---

## 14. Resources

- Full code patterns (state machine, component system, object pool, scene manager, save system): `resources/implementation-playbook.md`
- [Godot 4 docs](https://docs.godotengine.org/en/stable/)
- [GDQuest design patterns](https://www.gdquest.com/tutorial/godot/design-patterns/)
- [Chickensoft C# ecosystem](https://chickensoft.games)
