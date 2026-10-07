class_name TntBehavior
extends BrickBehavior

## Explosive brick: when destroyed, destroys the 8 bricks around it regardless of their hp
## (indestructible bricks survive). Neighboring TNT explodes in turn, a short moment later,
## so a chain reaction spreads visibly and never recurses deeply.

## Delay before neighbors are destroyed, in seconds.
const CHAIN_DELAY: float = 0.05
const LABEL_TEXT: String = "TNT"
const LABEL_COLOR: Color = Color(1.0, 0.85, 0.2)
const LABEL_OUTLINE_COLOR: Color = Color(0.25, 0.0, 0.0)
const LABEL_OUTLINE_SIZE: int = 3
## Pixel font size; multiples of 8 keep Press Start 2P crisp.
const LABEL_FONT_SIZE: int = 16


func on_destroyed(brick: Brick, grid: BrickGrid) -> void:
	if grid == null:
		return
	var targets := grid.neighbors(brick.cell)
	if targets.is_empty():
		return
	# The timer belongs to the SceneTree, not to the brick that is being freed. If a target
	# is freed before the timer fires, Godot drops that connection on its own.
	var timer := brick.get_tree().create_timer(CHAIN_DELAY)
	for target in targets:
		timer.timeout.connect(target.destroy)


func draw(brick: Brick) -> void:
	var font := RetroDraw.font()
	var font_size := LABEL_FONT_SIZE
	var text_size := font.get_string_size(LABEL_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(-text_size.x / 2.0, font.get_ascent(font_size) - text_size.y / 2.0)
	brick.draw_string_outline(font, baseline, LABEL_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			LABEL_OUTLINE_SIZE, LABEL_OUTLINE_COLOR)
	brick.draw_string(font, baseline, LABEL_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			LABEL_COLOR)
