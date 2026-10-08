class_name Projectile
extends Node2D

## A shot fired from the paddle (laser, missile power-ups). Flies straight up and checks for
## hits with a ray cast from its last position, so it cannot skip thin bricks at high speed.
## A laser bolt damages one brick like a ball hit; a missile destroys the whole row it hits.

enum Kind { LASER, MISSILE }

const WALLS_MASK: int = 1
const BRICKS_MASK: int = 8
const LASER_SPEED: float = 900.0
const MISSILE_SPEED: float = 620.0
const LASER_SIZE: Vector2 = Vector2(3, 14)
const LASER_COLOR: Color = Color(1.0, 0.3, 0.35)
const LASER_CORE: Color = Color(1.0, 0.9, 0.9)
const MISSILE_COLOR: Color = Color(0.85, 0.88, 0.95)
const MISSILE_TIP: Color = Color(0.9, 0.2, 0.25)
const FLAME_COLOR: Color = Color(1.0, 0.65, 0.2)
const GROUP: StringName = &"projectiles"

var kind: Kind = Kind.LASER

var _time: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)


func _physics_process(delta: float) -> void:
	_time += delta
	var speed := MISSILE_SPEED if kind == Kind.MISSILE else LASER_SPEED
	var from := global_position
	var to := from + Vector2.UP * speed * delta
	var query := PhysicsRayQueryParameters2D.create(from, to, WALLS_MASK | BRICKS_MASK)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
		queue_redraw()
		return
	var brick := hit.collider as Brick
	if brick != null:
		_hit_brick(brick, hit.position)
	queue_free()


func _hit_brick(brick: Brick, at: Vector2) -> void:
	if kind == Kind.LASER:
		brick.hit(null)
		return
	EventBus.explosion.emit(at)
	if brick.grid == null:
		brick.destroy()
		return
	for other in brick.grid.bricks():
		if other.cell.y == brick.cell.y:
			other.destroy()


func _draw() -> void:
	if kind == Kind.LASER:
		draw_rect(Rect2(-LASER_SIZE / 2.0, LASER_SIZE), LASER_COLOR)
		draw_rect(Rect2(Vector2(-0.5, -LASER_SIZE.y / 2.0), Vector2(1, LASER_SIZE.y)), LASER_CORE)
		return
	var flicker := 4.0 + sin(_time * 40.0) * 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, 9), Vector2(3, 9), Vector2(0, 9 + flicker * 2.0)]), FLAME_COLOR)
	draw_rect(Rect2(-4, -6, 8, 15), MISSILE_COLOR)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -6), Vector2(4, -6), Vector2(0, -13)]),
			MISSILE_TIP)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, 4), Vector2(-8, 10), Vector2(-4, 9)]),
			MISSILE_TIP)
	draw_colored_polygon(PackedVector2Array([Vector2(4, 4), Vector2(8, 10), Vector2(4, 9)]),
			MISSILE_TIP)
