class_name PowerUpManager
extends Node

## Spawns power-up capsules from broken bricks, applies collected power-ups and keeps track of
## active effects and their timers (DESIGN.md "Power-up sistem"). Reacts to EventBus signals on
## its own; Game only hands it the GameContext and the level, and clears it between lives.

const DROP_SCENE: PackedScene = preload("res://scenes/game/power_up_drop.tscn")

## Most capsules falling at the same time.
@export var max_falling: int = 3

## Every known power-up, by id.
var defs: Dictionary[String, PowerUpDef] = {}

var _ctx: GameContext = null
var _level: LevelData = null
var _active: Array[PowerUpEffect] = []
var _falling: Array[PowerUpDrop] = []
var _combo: float = ScoreTracker.COMBO_START
var _rng := RandomNumberGenerator.new()
## Last summary sent to the HUD, to send only changes.
var _last_summary: PackedStringArray = []


func _ready() -> void:
	_load_defs()
	_rng.randomize()
	EventBus.brick_destroyed.connect(_on_brick_destroyed)
	EventBus.combo_changed.connect(func(combo: float) -> void: _combo = combo)


func setup(ctx: GameContext) -> void:
	_ctx = ctx


func set_level(level: LevelData) -> void:
	_level = level


## Ends every active effect and removes falling capsules (life lost, new level, game over).
func clear_all() -> void:
	for effect in _active:
		effect.remove(_ctx)
	_active.clear()
	for drop in _falling:
		drop.queue_free()
	_falling.clear()
	_emit_summary()


## Applies a power-up as if it was collected (also used by tests and debugging).
func activate(def: PowerUpDef) -> void:
	var r := PowerUpRules.resolve(_active, def)
	for effect in r.remove:
		effect.remove(_ctx)
		_active.erase(effect)
	if r.refresh != null:
		r.refresh.time_left = def.duration
	if r.apply_new:
		var effect := def.effect.new() as PowerUpEffect
		effect.def = def
		effect.time_left = def.duration
		effect.apply(_ctx)
		if r.keep_active:
			_active.append(effect)
	_emit_summary()


func active_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for effect in _active:
		ids.append(effect.def.id)
	return ids


func _physics_process(delta: float) -> void:
	if _active.is_empty():
		return
	for effect in _active.duplicate():
		effect.tick(_ctx, delta)
		if not effect.def.is_timed():
			continue
		effect.time_left -= delta
		if effect.time_left <= 0.0:
			effect.remove(_ctx)
			_active.erase(effect)
	_emit_summary()


func _on_brick_destroyed(brick: Brick) -> void:
	if _ctx == null or _level == null or _falling.size() >= max_falling:
		return
	var brick_type := brick.brick_type
	var chance := DropSelector.drop_chance(brick_type.drop_chance, _level.drop_modifier, _combo)
	if not DropSelector.should_drop(chance, _rng.randf()):
		return
	var all: Array[PowerUpDef] = []
	all.assign(defs.values())
	var candidates := DropSelector.candidates(all, _level.allowed_powerups,
			_level.banned_powerups, brick_type.drop_positive_only)
	var def := DropSelector.pick(candidates, _rng.randf())
	if def != null:
		_spawn_drop(def, brick.global_position)


func _spawn_drop(def: PowerUpDef, at: Vector2) -> void:
	var drop: PowerUpDrop = DROP_SCENE.instantiate()
	drop.def = def
	drop.position = at
	drop.collected.connect(_on_drop_collected)
	drop.tree_exiting.connect(func() -> void: _falling.erase(drop))
	_falling.append(drop)
	add_child(drop)


func _on_drop_collected(drop: PowerUpDrop) -> void:
	# This runs inside the physics step (Area2D body_entered). Effects change collision shapes
	# and add bodies, which Godot forbids until the step ends, so apply at the end of the frame.
	_apply_collected.call_deferred(drop.def)


func _apply_collected(def: PowerUpDef) -> void:
	EventBus.powerup_collected.emit(def.id)
	activate(def)


func _emit_summary() -> void:
	var summary := PackedStringArray()
	for effect in _active:
		var text := tr(effect.def.display_name)
		if effect.def.is_timed():
			text += " %d" % ceili(effect.time_left)
		summary.append(text)
	if summary != _last_summary:
		_last_summary = summary
		EventBus.active_powerups_changed.emit(summary)


func _load_defs() -> void:
	defs = PowerUpCatalog.load_all()
