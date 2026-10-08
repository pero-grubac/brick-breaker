class_name GameEffects
extends Node2D

## "Juice" for the game scene (DESIGN.md "Audio i vizuelni efekti"): particle bursts, screen
## shake, hit stop, floating points and combo text. Reacts to EventBus only; nothing in the game
## depends on it, so it can be removed or toned down without touching gameplay.

const BURST_AMOUNT: int = 14
const EXPLOSION_AMOUNT: int = 40
const EXPLOSION_COLORS: Array[Color] = [Color(1.0, 0.85, 0.2), Color(1.0, 0.45, 0.1), Color(0.9, 0.15, 0.1)]
const POINTS_COLOR: Color = Color(1.0, 1.0, 1.0)
const COMBO_COLOR: Color = Color(1.0, 0.84, 0.2)
const COMBO_TEXT_POSITION: Vector2 = Vector2(640, 600)

## Screen shake: "trauma" from 0 to 1 that decays; the offset grows with trauma squared.
const MAX_SHAKE_OFFSET: float = 14.0
const TRAUMA_DECAY: float = 1.8
const EXPLOSION_TRAUMA: float = 0.35
const BALL_LOST_TRAUMA: float = 0.6
## Hit stop: the game freezes for a moment on an explosion.
const HIT_STOP_SCALE: float = 0.05
const HIT_STOP_TIME: float = 0.045
## Lightning power-up bolt.
const LIGHTNING_COLOR: Color = Color(0.7, 0.9, 1.0)
const LIGHTNING_WIDTH: float = 3.0
const LIGHTNING_SEGMENTS: int = 7
const LIGHTNING_JITTER: float = 18.0
const LIGHTNING_TOP_Y: float = 0.0
const LIGHTNING_TIME: float = 0.35
const LIGHTNING_TRAUMA: float = 0.15
## Explosive ball: a small blast on every hit (no hit stop, it happens too often).
const SMALL_EXPLOSION_AMOUNT: int = 16
const SMALL_EXPLOSION_TRAUMA: float = 0.08
const SHIELD_COLORS: Array[Color] = [Color(0.6, 0.95, 1.0), Color(0.3, 0.7, 1.0)]

## Camera whose offset is shaken (the HUD is on its own CanvasLayer and does not shake).
@export var camera: Camera2D

var _trauma: float = 0.0
var _last_combo: float = 1.0
var _hit_stop_active: bool = false
## The combo text on screen; a newer combo replaces it instead of drawing over it.
var _combo_text: FloatingText = null
## Game speed outside hit stop (slow motion lowers it).
var _base_time_scale: float = 1.0


func _ready() -> void:
	EventBus.brick_destroyed.connect(_on_brick_destroyed)
	EventBus.explosion.connect(_on_explosion)
	EventBus.lightning_struck.connect(_on_lightning_struck)
	EventBus.ball_exploded.connect(_on_ball_exploded)
	EventBus.shield_hit.connect(_on_shield_hit)
	EventBus.time_scale_changed.connect(func(scale: float) -> void: _base_time_scale = scale)
	EventBus.points_scored.connect(_on_points_scored)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.ball_lost.connect(func() -> void: add_trauma(BALL_LOST_TRAUMA))


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	if camera == null:
		return
	if _trauma <= 0.0:
		camera.offset = Vector2.ZERO
		return
	_trauma = maxf(_trauma - TRAUMA_DECAY * delta, 0.0)
	var amount := _trauma * _trauma * MAX_SHAKE_OFFSET
	camera.offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


func _on_brick_destroyed(brick: Brick) -> void:
	_burst(brick.global_position, [brick.brick_type.color, brick.brick_type.color.lightened(0.4)],
			BURST_AMOUNT, 160.0, Vector2(brick.size.x / 2.0, brick.size.y / 2.0))


func _on_explosion(at: Vector2) -> void:
	_burst(at, EXPLOSION_COLORS, EXPLOSION_AMOUNT, 320.0, Vector2(20, 10))
	add_trauma(EXPLOSION_TRAUMA)
	_hit_stop()


func _on_points_scored(points: int, at: Vector2) -> void:
	var text := FloatingText.new()
	text.text = "+%d" % points
	text.color = POINTS_COLOR
	text.font_size = 8
	text.position = at
	text.rise = 28.0
	text.pop = 1.3
	add_child(text)


func _on_combo_changed(combo: float) -> void:
	if combo > _last_combo and combo >= 2.0:
		var text := FloatingText.new()
		text.text = "x%s!" % String.num(combo, 1)
		text.color = COMBO_COLOR
		text.font_size = 32
		text.position = COMBO_TEXT_POSITION
		text.rise = 60.0
		text.duration = 0.9
		text.pop = 2.0
		if is_instance_valid(_combo_text):
			_combo_text.queue_free()
		_combo_text = text
		add_child(text)
	_last_combo = combo


## One-shot particle burst. CPU particles work on the web and low-end phones (DESIGN.md).
func _burst(at: Vector2, colors: Array[Color], amount: int, speed: float, area: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.position = at
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.6
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = area
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0, 520)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	var gradient := Gradient.new()
	gradient.set_color(0, colors[0])
	gradient.set_color(1, Color(colors[-1], 0.0))
	particles.color_ramp = gradient
	particles.finished.connect(particles.queue_free)
	add_child(particles)
	particles.emitting = true


func _hit_stop() -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	Engine.time_scale = HIT_STOP_SCALE
	# The timer ignores the time scale, so it lasts HIT_STOP_TIME of real time.
	await get_tree().create_timer(HIT_STOP_TIME, true, false, true).timeout
	# Back to the current base speed: slow motion may have started or ended meanwhile.
	Engine.time_scale = _base_time_scale
	_hit_stop_active = false


func _on_ball_exploded(at: Vector2) -> void:
	_burst(at, EXPLOSION_COLORS, SMALL_EXPLOSION_AMOUNT, 220.0, Vector2(30, 14))
	add_trauma(SMALL_EXPLOSION_TRAUMA)


func _on_shield_hit(at: Vector2, _hits_left: int) -> void:
	_burst(at, SHIELD_COLORS, BURST_AMOUNT, 200.0, Vector2(60, 2))


## Lightning bolt from the top of the arena down to the struck brick.
func _on_lightning_struck(at: Vector2) -> void:
	var bolt := Line2D.new()
	bolt.width = LIGHTNING_WIDTH
	bolt.default_color = LIGHTNING_COLOR
	var top := Vector2(at.x + randf_range(-60.0, 60.0), LIGHTNING_TOP_Y)
	for i in LIGHTNING_SEGMENTS + 1:
		var point := top.lerp(at, float(i) / LIGHTNING_SEGMENTS)
		if i > 0 and i < LIGHTNING_SEGMENTS:
			point.x += randf_range(-LIGHTNING_JITTER, LIGHTNING_JITTER)
		bolt.add_point(point)
	add_child(bolt)
	_burst(at, [LIGHTNING_COLOR, Color.WHITE], BURST_AMOUNT, 220.0, Vector2(10, 6))
	add_trauma(LIGHTNING_TRAUMA)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, LIGHTNING_TIME)
	tween.tween_callback(bolt.queue_free)
