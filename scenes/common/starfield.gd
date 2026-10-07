class_name Starfield
extends Node2D

## Retro animated background: three layers of square pixel stars drifting down at different
## speeds (parallax), with a slow twinkle. Fills the visible viewport, so it also covers the
## extra height of tall windows.

## Stars per layer, from far (slow, dim) to near (fast, bright).
const LAYER_COUNTS: Array[int] = [70, 40, 18]
const LAYER_SPEEDS: Array[float] = [6.0, 14.0, 32.0]
const LAYER_SIZES: Array[float] = [2.0, 2.0, 3.0]
const LAYER_ALPHAS: Array[float] = [0.35, 0.6, 0.9]
const STAR_COLORS: Array[Color] = [
	Color(1, 1, 1), Color(0.6, 0.85, 1.0), Color(1.0, 0.9, 0.6), Color(1.0, 0.65, 0.8),
]
const TWINKLE_SPEED: float = 2.0
const TWINKLE_AMOUNT: float = 0.35

@export var seed_value: int = 1987

## Per star: position (x, y), layer, color index and twinkle phase.
var _stars: Array[Dictionary] = []
var _time: float = 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var area := get_viewport_rect().size
	for layer in LAYER_COUNTS.size():
		for i in LAYER_COUNTS[layer]:
			_stars.append({
				"pos": Vector2(rng.randf() * area.x, rng.randf() * area.y),
				"layer": layer,
				"color": rng.randi() % STAR_COLORS.size(),
				"phase": rng.randf() * TAU,
			})


func _process(delta: float) -> void:
	_time += delta
	var height := get_viewport_rect().size.y
	for star in _stars:
		var pos: Vector2 = star.pos
		pos.y += LAYER_SPEEDS[star.layer] * delta
		if pos.y > height:
			pos.y -= height
		star.pos = pos
	queue_redraw()


func _draw() -> void:
	for star in _stars:
		var layer: int = star.layer
		var twinkle := 1.0 - TWINKLE_AMOUNT * (0.5 + 0.5 * sin(_time * TWINKLE_SPEED + star.phase))
		var color: Color = STAR_COLORS[star.color]
		color.a = LAYER_ALPHAS[layer] * twinkle
		var s := LAYER_SIZES[layer]
		var pos: Vector2 = star.pos
		draw_rect(Rect2(pos.floor(), Vector2(s, s)), color)
