class_name BrickType
extends Resource

## Data for one kind of brick. The Brick scene is the same for every type and only reads this.
## Adding a brick type = adding a .tres file in res://data/bricks/; only special behaviors
## (explosions, movement) need a script.

## Hit points value that marks a brick as indestructible.
const INDESTRUCTIBLE: int = -1

## Unique id used in level files ("normal", "steel", "tnt"...).
@export var id: String = ""
## Hits needed to break the brick; INDESTRUCTIBLE (-1) means it never breaks.
@export var hp: int = 1
@export var points: int = 50
## Chance (0..1) that breaking this brick drops a power-up (used from phase 3).
@export_range(0.0, 1.0) var drop_chance: float = 0.1
## Drops only positive power-ups (the "bonus" brick).
@export var drop_positive_only: bool = false
## Whether the brick must be broken to clear the level.
@export var counts_for_clear: bool = true
## Placeholder color until real graphics arrive (phase 5).
@export var color: Color = Color.WHITE
@export var texture: Texture2D
## Optional special behavior script (see scripts/bricks/).
@export var behavior: GDScript


func is_indestructible() -> bool:
	return hp == INDESTRUCTIBLE
