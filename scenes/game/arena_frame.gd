class_name ArenaFrame
extends Node2D

## Retro metal frame drawn over the walls: bevelled pipes with bolts. Purely visual; the walls'
## collision shapes stay on their StaticBody2D nodes.

const OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.06)
const BEVEL: float = 4.0
## Distance between the bolt plates along the frame.
const SEGMENT: float = 80.0
const PLATE: float = 14.0

@export var thickness: float = 20.0
@export var color: Color = Color(0.42, 0.46, 0.6)
@export var plate_color: Color = Color(0.25, 0.85, 0.95)


func _draw() -> void:
	var area := get_viewport_rect().size
	var left := Rect2(0, 0, thickness, area.y)
	var right := Rect2(area.x - thickness, 0, thickness, area.y)
	var top := Rect2(0, 0, area.x, thickness)
	for r in [left, right, top]:
		RetroDraw.bevel_rect(self, r, color, BEVEL, 0.45, 0.55, OUTLINE_COLOR)
	# Bolt plates
	var y := SEGMENT
	while y < area.y:
		_plate(Vector2(thickness / 2.0, y))
		_plate(Vector2(area.x - thickness / 2.0, y))
		y += SEGMENT
	var x := SEGMENT
	while x < area.x - SEGMENT / 2.0:
		_plate(Vector2(x, thickness / 2.0))
		x += SEGMENT * 2.0


func _plate(center: Vector2) -> void:
	var half := Vector2(PLATE, PLATE) / 2.0
	RetroDraw.bevel_rect(self, Rect2(center - half, half * 2.0), plate_color, 2.0, 0.5, 0.5,
			OUTLINE_COLOR)
