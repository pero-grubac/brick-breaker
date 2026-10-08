class_name Brick
extends StaticBody2D

## A brick the ball can break. All data comes from its BrickType; the brick only tracks
## remaining hp, draws itself and announces its destruction on the EventBus. A type with a
## `behavior` script (TNT, portal, moving...) gets an instance of it for special effects.

## Retro look: dark outline and a bevel (light top/left, dark bottom/right).
const OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.06)
const BEVEL: float = 3.0
const BEVEL_LIGHTEN: float = 0.45
const BEVEL_DARKEN: float = 0.45
const CRACK_COLOR: Color = Color(0.1, 0.1, 0.12, 0.85)
## Hit flash: colors above 1.0 make the brick brighter than its normal color.
const FLASH_COLOR: Color = Color(2.2, 2.2, 2.2)
const FLASH_TIME: float = 0.12

## Must be set before the brick enters the tree.
@export var brick_type: BrickType
@export var size: Vector2 = Vector2(64.0, 20.0):
	set(value):
		size = value
		if is_node_ready():
			_apply_size()

## Level cell (column, row) and the grid this brick is registered in; set by Game.
var cell: Vector2i = Vector2i.ZERO
var grid: BrickGrid = null
var hp: int = 0
var _destroyed: bool = false
var _behavior: BrickBehavior = null

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	assert(brick_type != null, "Brick needs a BrickType before entering the tree")
	hp = brick_type.hp
	if brick_type.behavior != null:
		_behavior = brick_type.behavior.new() as BrickBehavior
		_behavior.setup(self)
	set_physics_process(_behavior != null and _behavior.wants_tick())
	_apply_size()


func _physics_process(delta: float) -> void:
	_behavior.tick(self, delta)


func counts_for_clear() -> bool:
	return brick_type.counts_for_clear


func behavior() -> BrickBehavior:
	return _behavior


## Called by the ball on collision: costs one hp. Returns true if the ball passes through
## without bouncing (the behavior handled the hit, e.g. a portal).
func hit(ball: Ball) -> bool:
	if _destroyed:
		return false
	if _behavior != null and _behavior.on_hit(self, ball):
		return true
	damage(1)
	return false


## Takes `amount` hp. Indestructible bricks only flash.
func damage(amount: int) -> void:
	if _destroyed:
		return
	if brick_type.is_indestructible():
		_flash()
		EventBus.brick_damaged.emit(self)
		return
	hp -= amount
	if hp > 0:
		queue_redraw()
		_flash()
		if _behavior != null:
			_behavior.on_damaged(self)
		EventBus.brick_damaged.emit(self)
		return
	destroy()


## Restores hp (regenerating bricks, the "fortify" power-up). `max_hp` defaults to the type's.
func heal(amount: int, max_hp: int = -1) -> void:
	if _destroyed or brick_type.is_indestructible():
		return
	var limit := brick_type.hp if max_hp < 0 else max_hp
	hp = mini(hp + amount, limit)
	queue_redraw()


## Destroys the brick at once, whatever its hp (explosions). Indestructible bricks ignore
## it unless `force` is set (fire ball).
func destroy(force: bool = false) -> void:
	if _destroyed or (brick_type.is_indestructible() and not force):
		return
	_destroyed = true
	# Stop colliding right away; queue_free() only removes the node at the end of the frame.
	collision_layer = 0
	if grid != null:
		grid.remove(cell, self)
	EventBus.brick_destroyed.emit(self)
	if _behavior != null:
		_behavior.on_destroyed(self, grid)
	queue_free()


func is_destroyed() -> bool:
	return _destroyed


## Short white flash when the brick is hit but survives.
func _flash() -> void:
	modulate = FLASH_COLOR
	create_tween().tween_property(self, "modulate", Color.WHITE, FLASH_TIME)


func _draw() -> void:
	if _behavior != null and not _behavior.is_visible(self):
		return
	var rect := Rect2(-size / 2.0, size)
	RetroDraw.bevel_rect(self, rect, brick_type.color, BEVEL, BEVEL_LIGHTEN, BEVEL_DARKEN,
			OUTLINE_COLOR)
	var taken := maxi(brick_type.hp, hp) - hp
	if not brick_type.is_indestructible() and taken > 0:
		_draw_cracks(taken)
	BrickMarks.draw(self, rect, brick_type.id)
	if _behavior != null:
		_behavior.draw(self)


## One crack per hit taken: a zigzag line across the brick, each one in a different spot.
func _draw_cracks(taken: int) -> void:
	var half := size / 2.0
	for i in mini(taken, 3):
		var x := lerpf(-half.x, half.x, 0.25 + 0.25 * i)
		var points := PackedVector2Array([
			Vector2(x - 6.0, -half.y),
			Vector2(x + 3.0, -half.y * 0.3),
			Vector2(x - 3.0, half.y * 0.3),
			Vector2(x + 5.0, half.y),
		])
		draw_polyline(points, CRACK_COLOR, 1.5, true)


func _apply_size() -> void:
	(_collision.shape as RectangleShape2D).size = size
	queue_redraw()
