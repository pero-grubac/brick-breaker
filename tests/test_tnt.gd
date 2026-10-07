extends GutTest

## Integration tests for TNT bricks: real Brick scenes in a BrickGrid, laid out from strings.

const BRICK_SCENE: PackedScene = preload("res://scenes/game/brick.tscn")
const LEGEND: Dictionary[String, String] = {
	"n": "normal", "H": "hard3", "S": "steel", "T": "tnt",
}
## Longer than TntBehavior.CHAIN_DELAY times the longest chain in these tests.
const WAIT: float = 0.4

var _grid: BrickGrid
## Destruction reports per brick, keyed by instance id (freed bricks cannot be keys).
var _destroyed_count: Dictionary[int, int] = {}


func before_each() -> void:
	_grid = BrickGrid.new()
	_destroyed_count.clear()
	EventBus.brick_destroyed.connect(_on_brick_destroyed)


func after_each() -> void:
	EventBus.brick_destroyed.disconnect(_on_brick_destroyed)


func _on_brick_destroyed(brick: Brick) -> void:
	var id := brick.get_instance_id()
	_destroyed_count[id] = _destroyed_count.get(id, 0) + 1


## Builds bricks from rows like "nTn"; "." is empty. Returns cell -> brick.
func _build(rows: Array[String]) -> Dictionary[Vector2i, Brick]:
	var bricks: Dictionary[Vector2i, Brick] = {}
	for r in rows.size():
		for c in rows[r].length():
			var symbol := rows[r][c]
			if symbol == ".":
				continue
			var brick: Brick = BRICK_SCENE.instantiate()
			brick.brick_type = LevelLoader.get_brick_type(LEGEND[symbol])
			brick.cell = Vector2i(c, r)
			brick.grid = _grid
			_grid.add(brick.cell, brick)
			add_child_autofree(brick)
			bricks[brick.cell] = brick
	return bricks


## Variant, not Brick: a typed parameter rejects an instance that was already freed.
func _alive(brick: Variant) -> bool:
	return is_instance_valid(brick) and not brick.is_destroyed()


func test_tnt_destroys_all_8_neighbors() -> void:
	var b := _build(["nnn", "nTn", "nnn"])
	b[Vector2i(1, 1)].destroy()
	await wait_seconds(WAIT)
	for cell in b:
		assert_false(_alive(b[cell]), "cell %s destroyed" % cell)


func test_tnt_does_not_reach_two_cells_away() -> void:
	var b := _build(["Tnn"])
	b[Vector2i(0, 0)].destroy()
	await wait_seconds(WAIT)
	assert_false(_alive(b[Vector2i(1, 0)]))
	assert_true(_alive(b[Vector2i(2, 0)]))


func test_explosion_ignores_hp() -> void:
	var b := _build(["TH"])
	b[Vector2i(0, 0)].destroy()
	await wait_seconds(WAIT)
	assert_false(_alive(b[Vector2i(1, 0)]), "hard3 breaks in one explosion")


func test_steel_survives_explosion() -> void:
	var b := _build(["TS"])
	b[Vector2i(0, 0)].destroy()
	await wait_seconds(WAIT)
	assert_true(_alive(b[Vector2i(1, 0)]))


func test_chain_reaction_through_adjacent_tnt() -> void:
	var b := _build(["TTTTn.n"])
	b[Vector2i(0, 0)].destroy()
	await wait_seconds(WAIT)
	assert_false(_alive(b[Vector2i(4, 0)]), "reached by the last TNT in the chain")
	assert_true(_alive(b[Vector2i(6, 0)]), "gap stops the chain")


func test_chain_is_not_instant() -> void:
	var b := _build(["Tn"])
	b[Vector2i(0, 0)].destroy()
	assert_true(_alive(b[Vector2i(1, 0)]), "neighbors go after a short delay")
	await wait_seconds(WAIT)
	assert_false(_alive(b[Vector2i(1, 0)]))


func test_each_brick_reports_destruction_once() -> void:
	var b := _build(["TTT", "TTT"])
	b[Vector2i(0, 0)].destroy()
	await wait_seconds(WAIT)
	assert_eq(_destroyed_count.size(), 6)
	for id in _destroyed_count:
		assert_eq(_destroyed_count[id], 1)


func test_ball_hit_on_tnt_explodes_it() -> void:
	var b := _build(["Tn"])
	b[Vector2i(0, 0)].hit(null)
	await wait_seconds(WAIT)
	assert_false(_alive(b[Vector2i(1, 0)]))
