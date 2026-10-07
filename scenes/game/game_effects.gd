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

## Camera whose offset is shaken (the HUD is on its own CanvasLayer and does not shake).
@export var camera: Camera2D

var _trauma: float = 0.0
var _last_combo: float = 1.0
var _hit_stop_active: bool = false


func _ready() -> void:
	EventBus.brick_destroyed.connect(_on_brick_destroyed)
	EventBus.explosion.connect(_on_explosion)
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
	Engine.time_scale = 1.0
	_hit_stop_active = false
