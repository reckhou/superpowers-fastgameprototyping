# Godot Workflow — Implementation Playbook

Full code patterns referenced by `SKILL.md`.

---

## Pattern 1: Player Script (GDScript)

```gdscript
class_name Player
extends CharacterBody2D

signal health_changed(new_health: int)
signal died

@export var speed: float = 200.0
@export var max_health: int = 100
@export_group("Combat")
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation: AnimationPlayer = $AnimationPlayer

var _health: int
var _can_attack: bool = true

func _ready() -> void:
    _health = max_health

func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("left", "right", "up", "down")
    velocity = direction * speed
    move_and_slide()

func take_damage(amount: int) -> void:
    _health = max(_health - amount, 0)
    health_changed.emit(_health)
    if _health <= 0:
        died.emit()
```

---

## Pattern 2: Node-Based State Machine (GDScript)

```gdscript
# state_machine.gd
class_name StateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name] = child
            child.state_machine = self
            child.process_mode = Node.PROCESS_MODE_DISABLED

    if initial_state:
        current_state = initial_state
        current_state.process_mode = Node.PROCESS_MODE_INHERIT
        current_state.enter()

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
    if not states.has(state_name):
        push_error("State '%s' not found" % state_name)
        return

    current_state.exit()
    current_state.process_mode = Node.PROCESS_MODE_DISABLED

    current_state = states[state_name]
    current_state.process_mode = Node.PROCESS_MODE_INHERIT
    current_state.enter(msg)

    state_changed.emit(current_state.name, state_name)
```

```gdscript
# state.gd — base class
class_name State
extends Node

var state_machine: StateMachine

func enter(_msg: Dictionary = {}) -> void: pass
func exit() -> void: pass
func update(_delta: float) -> void: pass
func physics_update(_delta: float) -> void: pass
func handle_input(_event: InputEvent) -> void: pass
```

```gdscript
# player_idle.gd
class_name PlayerIdle
extends State

@export var player: Player

func enter(_msg: Dictionary = {}) -> void:
    player.animation.play("idle")

func physics_update(_delta: float) -> void:
    if Input.get_vector("left", "right", "up", "down") != Vector2.ZERO:
        state_machine.transition_to("Move")

func handle_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack"):
        state_machine.transition_to("Attack")
    elif event.is_action_pressed("jump"):
        state_machine.transition_to("Jump")
```

---

## Pattern 3: Component System (GDScript)

### HealthComponent
```gdscript
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal damaged(amount: int, source: Node)
signal died

@export var max_health: int = 100
@export var invincibility_time: float = 0.0

var current_health: int:
    set(value):
        var old := current_health
        current_health = clampi(value, 0, max_health)
        if current_health != old:
            health_changed.emit(current_health, max_health)

var _invincible: bool = false

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int, source: Node = null) -> int:
    if _invincible or current_health <= 0:
        return 0

    var actual := mini(amount, current_health)
    current_health -= actual
    damaged.emit(actual, source)

    if current_health <= 0:
        died.emit()
    elif invincibility_time > 0:
        _start_invincibility()

    return actual

func heal(amount: int) -> int:
    var actual := mini(amount, max_health - current_health)
    current_health += actual
    return actual

func _start_invincibility() -> void:
    _invincible = true
    await get_tree().create_timer(invincibility_time).timeout
    _invincible = false
```

### HitboxComponent + HurtboxComponent
```gdscript
# hitbox_component.gd
class_name HitboxComponent
extends Area2D

@export var damage: int = 10

var owner_node: Node

func _ready() -> void:
    owner_node = get_parent()
    area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
    if area is HurtboxComponent and area.owner_node != owner_node:
        area.receive_hit(self)
```

```gdscript
# hurtbox_component.gd
class_name HurtboxComponent
extends Area2D

@export var health_component: HealthComponent

var owner_node: Node

func _ready() -> void:
    owner_node = get_parent()

func receive_hit(hitbox: HitboxComponent) -> void:
    if health_component:
        health_component.take_damage(hitbox.damage, hitbox.owner_node)
```

Scene structure:
```
Player (CharacterBody2D)
  ├── HealthComponent (Node)
  └── HurtboxComponent (Area2D)
        └── CollisionShape2D

Enemy (CharacterBody2D)
  ├── HealthComponent (Node)
  ├── HurtboxComponent (Area2D)
  └── HitboxComponent (Area2D)
```

---

## Pattern 4: Custom Resource (GDScript)

```gdscript
# weapon_data.gd
class_name WeaponData
extends Resource

@export var name: StringName
@export var damage: int
@export var attack_speed: float
@export var icon: Texture2D
@export var projectile_scene: PackedScene
@export_multiline var description: String
```

```gdscript
# character_stats.gd — runtime-safe resource with duplicate pattern
class_name CharacterStats
extends Resource

signal stat_changed(stat_name: StringName, new_value: float)

@export var max_health: float = 100.0
@export var speed: float = 200.0

var _current_health: float

func _init() -> void:
    _current_health = max_health

func take_damage(amount: float) -> void:
    _current_health = maxf(_current_health - amount, 0.0)
    stat_changed.emit("health", _current_health)
    if _current_health <= 0:
        stat_changed.emit("died", 0.0)

func duplicate_for_runtime() -> CharacterStats:
    var copy := duplicate() as CharacterStats
    copy._current_health = copy.max_health
    return copy
```

```gdscript
# Usage — always duplicate before runtime use
func _ready() -> void:
    stats = base_stats.duplicate_for_runtime()
    stats.stat_changed.connect(_on_stat_changed)
```

---

## Pattern 5: Object Pool (GDScript)

```gdscript
# object_pool.gd
class_name ObjectPool
extends Node

@export var pooled_scene: PackedScene
@export var initial_size: int = 10
@export var can_grow: bool = true

var _available: Array[Node] = []
var _in_use: Array[Node] = []

func _ready() -> void:
    for i in initial_size:
        _create_instance()

func _create_instance() -> void:
    var instance := pooled_scene.instantiate()
    instance.process_mode = Node.PROCESS_MODE_DISABLED
    instance.visible = false
    add_child(instance)
    _available.append(instance)
    if instance.has_signal("returned_to_pool"):
        instance.returned_to_pool.connect(_return_to_pool.bind(instance))

func get_instance() -> Node:
    if _available.is_empty():
        if can_grow:
            _create_instance()
        else:
            push_warning("Pool exhausted")
            return null

    var instance := _available.pop_back()
    instance.process_mode = Node.PROCESS_MODE_INHERIT
    instance.visible = true
    _in_use.append(instance)
    if instance.has_method("on_spawn"):
        instance.on_spawn()
    return instance

func _return_to_pool(instance: Node) -> void:
    if instance not in _in_use:
        return
    _in_use.erase(instance)
    if instance.has_method("on_despawn"):
        instance.on_despawn()
    instance.process_mode = Node.PROCESS_MODE_DISABLED
    instance.visible = false
    _available.append(instance)
```

```gdscript
# pooled_bullet.gd
class_name PooledBullet
extends Area2D

signal returned_to_pool

@export var speed: float = 500.0
@export var lifetime: float = 5.0

var direction: Vector2
var _timer: float

func on_spawn() -> void:
    _timer = lifetime

func initialize(pos: Vector2, dir: Vector2) -> void:
    global_position = pos
    direction = dir.normalized()
    rotation = direction.angle()

func _physics_process(delta: float) -> void:
    position += direction * speed * delta
    _timer -= delta
    if _timer <= 0:
        returned_to_pool.emit()

func _on_body_entered(body: Node2D) -> void:
    if body.has_method("take_damage"):
        body.take_damage(10)
    returned_to_pool.emit()
```

---

## Pattern 6: Event Bus Autoload (GDScript)

```gdscript
# GameEvents.gd — register as Autoload "GameEvents"
extends Node

# Player
signal player_spawned(player: Node2D)
signal player_died
signal player_health_changed(health: int, max_health: int)

# Enemies
signal enemy_died(enemy: Node2D, position: Vector2)

# Items
signal item_collected(item_type: StringName, value: int)

# Level
signal level_started(level_number: int)
signal level_completed(level_number: int, time: float)
```

Usage:
```gdscript
# Emit
GameEvents.player_died.emit()

# Connect
GameEvents.player_died.connect(_on_player_died)
GameEvents.player_died.connect(func(): $DeathScreen.show())
```

---

## Pattern 7: Scene Manager Autoload (GDScript)

```gdscript
# SceneManager.gd — register as Autoload
extends Node

signal scene_loaded(scene: Node)

var _current_scene: Node

func _ready() -> void:
    _current_scene = get_tree().current_scene

func change_scene(scene_path: String) -> void:
    _load_scene_async(scene_path)

func change_scene_packed(scene: PackedScene) -> void:
    _swap_scene(scene.instantiate())

func _load_scene_async(path: String) -> void:
    if ResourceLoader.has_cached(path):
        _swap_scene((load(path) as PackedScene).instantiate())
        return

    ResourceLoader.load_threaded_request(path)

    while true:
        var progress := []
        var status := ResourceLoader.load_threaded_get_status(path, progress)
        match status:
            ResourceLoader.THREAD_LOAD_IN_PROGRESS:
                await get_tree().process_frame
            ResourceLoader.THREAD_LOAD_LOADED:
                _swap_scene((ResourceLoader.load_threaded_get(path) as PackedScene).instantiate())
                return
            _:
                push_error("Failed to load scene: %s" % path)
                return

func _swap_scene(new_scene: Node) -> void:
    if _current_scene:
        _current_scene.queue_free()
    _current_scene = new_scene
    get_tree().root.add_child(_current_scene)
    get_tree().current_scene = _current_scene
    scene_loaded.emit(_current_scene)
```

---

## Pattern 8: Save System (GDScript)

```gdscript
# SaveManager.gd — register as Autoload
extends Node

const SAVE_PATH := "user://savegame.json"

signal save_completed
signal load_completed
signal save_error(message: String)

func save_game(data: Dictionary) -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        save_error.emit("Could not open save file: %d" % FileAccess.get_open_error())
        return
    file.store_string(JSON.stringify(data, "\t"))
    file.close()
    save_completed.emit()

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        save_error.emit("Could not open save file")
        return {}

    var parsed := JSON.parse_string(file.get_as_text())
    file.close()

    if parsed == null:
        save_error.emit("Could not parse save data")
        return {}

    load_completed.emit()
    return parsed

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
    if has_save():
        DirAccess.remove_absolute(SAVE_PATH)
```

---

## Pattern 9: C# State Machine

```csharp
// StateMachine.cs
public partial class StateMachine : Node
{
    [Export] public State InitialState { get; set; }

    private State _currentState;
    private Dictionary<StringName, State> _states = new();

    public override void _Ready()
    {
        foreach (var child in GetChildren())
        {
            if (child is State state)
            {
                _states[state.Name] = state;
                state.StateMachine = this;
                state.ProcessMode = ProcessModeEnum.Disabled;
            }
        }

        if (InitialState != null)
        {
            _currentState = InitialState;
            _currentState.ProcessMode = ProcessModeEnum.Inherit;
            _currentState.Enter();
        }
    }

    public override void _Process(double delta) => _currentState?.Update(delta);
    public override void _PhysicsProcess(double delta) => _currentState?.PhysicsUpdate(delta);
    public override void _UnhandledInput(InputEvent @event) => _currentState?.HandleInput(@event);

    public void TransitionTo(StringName stateName)
    {
        if (!_states.TryGetValue(stateName, out var next)) return;

        _currentState.Exit();
        _currentState.ProcessMode = ProcessModeEnum.Disabled;

        _currentState = next;
        _currentState.ProcessMode = ProcessModeEnum.Inherit;
        _currentState.Enter();
    }
}
```

```csharp
// State.cs — base class
public partial class State : Node
{
    public StateMachine StateMachine { get; set; }

    public virtual void Enter() { }
    public virtual void Exit() { }
    public virtual void Update(double delta) { }
    public virtual void PhysicsUpdate(double delta) { }
    public virtual void HandleInput(InputEvent @event) { }
}
```

---

## Pattern 10: C# HealthComponent

```csharp
public partial class HealthComponent : Node
{
    [Signal] public delegate void HealthChangedEventHandler(int current, int maximum);
    [Signal] public delegate void DiedEventHandler();

    [Export] public int MaxHealth { get; set; } = 100;

    private int _currentHealth;

    public override void _Ready()
    {
        _currentHealth = MaxHealth;
    }

    public int TakeDamage(int amount)
    {
        var actual = Math.Min(amount, _currentHealth);
        _currentHealth -= actual;
        EmitSignal(SignalName.HealthChanged, _currentHealth, MaxHealth);
        if (_currentHealth <= 0)
            EmitSignal(SignalName.Died);
        return actual;
    }

    public void Heal(int amount)
    {
        _currentHealth = Math.Min(_currentHealth + amount, MaxHealth);
        EmitSignal(SignalName.HealthChanged, _currentHealth, MaxHealth);
    }
}
```

---

## Pattern 11: @tool Script with Editor Button (Godot 4.4+)

```gdscript
@tool
extends Node

@export_tool_button("Regenerate") var _regen_btn = regenerate
@export_tool_button("Clear") var _clear_btn = clear_all

func regenerate() -> void:
    if not Engine.is_editor_hint():
        return
    # generate procedural content in editor
    pass

func clear_all() -> void:
    if not Engine.is_editor_hint():
        return
    for child in get_children():
        child.queue_free()
```

---

## Pattern 12: GUT Test (GDScript)

```gdscript
# test_health_component.gd
extends GutTest

var _health: HealthComponent

func before_each() -> void:
    _health = HealthComponent.new()
    _health.max_health = 100
    add_child_autofree(_health)

func test_starts_at_max_health() -> void:
    assert_eq(_health.current_health, 100)

func test_take_damage_reduces_health() -> void:
    _health.take_damage(30)
    assert_eq(_health.current_health, 70)

func test_cannot_go_below_zero() -> void:
    _health.take_damage(999)
    assert_eq(_health.current_health, 0)

func test_emits_died_signal_at_zero() -> void:
    watch_signals(_health)
    _health.take_damage(100)
    assert_signal_emitted(_health, "died")
```

---

## Pattern 13: C# Unit Test (GdUnit4Net / NUnit — No Godot Runtime)

```csharp
[TestFixture]
public class DamageCalculatorTests
{
    [Test]
    public void TakeDamage_ReducesHealth()
    {
        var calc = new DamageCalculator(maxHealth: 100);
        calc.TakeDamage(30);
        Assert.AreEqual(70, calc.CurrentHealth);
    }

    [Test]
    public void TakeDamage_CannotGoBelowZero()
    {
        var calc = new DamageCalculator(maxHealth: 100);
        calc.TakeDamage(999);
        Assert.AreEqual(0, calc.CurrentHealth);
    }

    [Test]
    public void Heal_CannotExceedMax()
    {
        var calc = new DamageCalculator(maxHealth: 100);
        calc.TakeDamage(50);
        calc.Heal(999);
        Assert.AreEqual(100, calc.CurrentHealth);
    }
}
```
