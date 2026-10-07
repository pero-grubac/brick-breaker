class_name PowerUpDef
extends Resource

## Data for one power-up. Behavior lives in the `effect` script (a PowerUpEffect subclass).
## Adding a power-up = a .tres file in res://data/powerups/ plus one effect script.

## How picking up a power-up combines with effects that are already active.
enum StackRule {
	## Same power-up active: restart its timer. Otherwise apply it.
	REFRESH,
	## Always apply another copy on top of the active ones.
	STACK,
	## Remove every active effect of the same exclusive_group (and this id), then apply.
	REPLACE,
	## Apply once, right away; never stays active.
	INSTANT,
}

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
## Placeholder look until real icons arrive (phase 5): capsule color and a short label.
@export var color: Color = Color.WHITE
@export var short_label: String = ""
@export var is_negative: bool = false
## Relative chance among the power-ups allowed in a level.
@export var weight: float = 1.0
## Seconds the effect lasts; 0 = until the ball is lost or the level ends.
@export var duration: float = 0.0
@export var stack_rule: StackRule = StackRule.REFRESH
## Effects in the same group exclude each other with REPLACE (e.g. "paddle_size").
@export var exclusive_group: String = ""
## Script extending PowerUpEffect.
@export var effect: GDScript


func is_timed() -> bool:
	return duration > 0.0
