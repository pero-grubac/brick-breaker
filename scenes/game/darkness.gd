class_name Darkness
extends ColorRect

## Darkness power-up: covers the arena in black except soft circles of light around the balls
## and the paddle. The holes are cut by a small shader; Game sends the light positions every
## physics frame with set_lights().

const MAX_LIGHTS: int = 12
const LIGHT_RADIUS: float = 120.0
const MAX_ALPHA: float = 0.97
const FADE_TIME: float = 0.4
const ARENA_SIZE: Vector2 = Vector2(1280, 720)
## Above bricks, balls and particles; the HUD is on its own CanvasLayer and stays visible.
const DRAW_ORDER: int = 50

const SHADER_CODE: String = """
shader_type canvas_item;

const int MAX_LIGHTS = 12;
uniform vec2 lights[MAX_LIGHTS];
uniform int light_count = 0;
uniform float radius = 120.0;
uniform float strength = 0.0;
uniform vec2 rect_size = vec2(1280.0, 720.0);

void fragment() {
	vec2 p = UV * rect_size;
	float lit = 0.0;
	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= light_count) {
			break;
		}
		lit = max(lit, 1.0 - smoothstep(radius * 0.45, radius, distance(p, lights[i])));
	}
	COLOR = vec4(0.0, 0.0, 0.0, strength * (1.0 - lit));
}
"""

var _material: ShaderMaterial = ShaderMaterial.new()


func _ready() -> void:
	size = ARENA_SIZE
	z_index = DRAW_ORDER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_material.shader = shader
	_material.set_shader_parameter("radius", LIGHT_RADIUS)
	_material.set_shader_parameter("rect_size", ARENA_SIZE)
	_material.set_shader_parameter("strength", 0.0)
	material = _material
	create_tween().tween_method(_set_strength, 0.0, MAX_ALPHA, FADE_TIME)


## Positions (in arena coordinates) that stay lit.
func set_lights(points: PackedVector2Array) -> void:
	if points.size() > MAX_LIGHTS:
		points.resize(MAX_LIGHTS)
	var padded := points.duplicate()
	padded.resize(MAX_LIGHTS)
	_material.set_shader_parameter("lights", padded)
	_material.set_shader_parameter("light_count", points.size())


## Fades the darkness out, then frees it.
func fade_out() -> void:
	var tween := create_tween()
	tween.tween_method(_set_strength, float(_material.get_shader_parameter("strength")), 0.0,
			FADE_TIME)
	tween.tween_callback(queue_free)


func _set_strength(value: float) -> void:
	_material.set_shader_parameter("strength", value)
