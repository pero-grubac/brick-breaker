class_name BrickBehavior
extends RefCounted

## Base class for special brick behaviors. A BrickType points to a subclass script in its
## `behavior` field; every brick of that type gets its own instance. Override what you need.


## Called once when the brick is destroyed, after it left the grid.
func on_destroyed(_brick: Brick, _grid: BrickGrid) -> void:
	pass


## Called at the end of the brick's _draw(); draw extra marks with the brick's draw_* methods.
func draw(_brick: Brick) -> void:
	pass
