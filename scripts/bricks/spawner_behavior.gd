class_name SpawnerBehavior
extends BrickBehavior

## Every few seconds asks the game to put a new normal brick in a free cell next to it,
## up to a limit, so the level keeps changing while you play.

const INTERVAL: float = 6.0
const MAX_SPAWNS: int = 6
const SPAWN_TYPE: String = "normal"

var _timer: float = 0.0
var _spawned: int = 0
var _rng := RandomNumberGenerator.new()


func setup(_brick: Brick) -> void:
	_rng.randomize()


func wants_tick() -> bool:
	return true


func tick(brick: Brick, delta: float) -> void:
	if _spawned >= MAX_SPAWNS or brick.grid == null:
		return
	_timer += delta
	if _timer < INTERVAL:
		return
	_timer = 0.0
	var free := free_neighbors(brick.grid, brick.cell)
	if free.is_empty():
		return
	_spawned += 1
	EventBus.brick_spawn_requested.emit(free[_rng.randi() % free.size()], SPAWN_TYPE)


static func free_neighbors(grid: BrickGrid, cell: Vector2i) -> Array[Vector2i]:
	var free: Array[Vector2i] = []
	for offset in BrickGrid.NEIGHBOR_OFFSETS:
		if grid.is_free(cell + offset):
			free.append(cell + offset)
	return free
