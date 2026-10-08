extends GutTest

## Tests for the special bricks: ghost, regen, moving, portal, spawner.

const BRICK_SCENE: PackedScene = preload("res://scenes/game/brick.tscn")

var _grid: BrickGrid


func before_each() -> void:
	_grid = BrickGrid.new()


## A real brick in the tree (behaviors run), registered in the grid.
func _brick(id: String, cell: Vector2i) -> Brick:
	var brick: Brick = BRICK_SCENE.instantiate()
	brick.brick_type = LevelLoader.get_brick_type(id)
	brick.cell = cell
	brick.grid = _grid
	brick.position = Vector2(cell.x * _grid.cell_step.x, cell.y * _grid.cell_step.y)
	_grid.add(cell, brick)
	return brick


## A bare Brick object for the grid-only (pure) tests.
func _stub(id: String, cell: Vector2i) -> Brick:
	var brick: Brick = autofree(Brick.new())
	brick.brick_type = LevelLoader.get_brick_type(id)
	brick.cell = cell
	_grid.add(cell, brick)
	return brick


# --- ghost ---

func test_ghost_is_hidden_until_hit() -> void:
	var ghost := _brick("ghost", Vector2i(3, 3))
	add_child_autofree(ghost)
	assert_false(ghost.behavior().is_visible(ghost))
	ghost.hit(null)
	assert_true(ghost.behavior().is_visible(ghost))
	assert_eq(ghost.hp, 1, "the revealing hit also does damage")


# --- regen ---

func test_regen_heals_after_a_while() -> void:
	var regen := _brick("regen", Vector2i(1, 1))
	add_child_autofree(regen)
	regen.hit(null)
	assert_eq(regen.hp, 1)
	await wait_seconds(RegenBehavior.REGEN_TIME + 0.3)
	assert_eq(regen.hp, regen.brick_type.hp)


func test_regen_can_still_be_destroyed() -> void:
	var regen := _brick("regen", Vector2i(1, 1))
	add_child_autofree(regen)
	regen.hit(null)
	regen.hit(null)
	assert_true(regen.is_destroyed())


# --- moving ---

func test_moving_span_covers_free_cells_beside_it() -> void:
	_stub("normal", Vector2i(2, 0))
	_stub("normal", Vector2i(9, 0))
	assert_eq(MovingBehavior.free_span(_grid, Vector2i(5, 0)), Vector2i(3, 8))


func test_moving_span_stops_at_the_grid_edges() -> void:
	assert_eq(MovingBehavior.free_span(_grid, Vector2i(5, 0)), Vector2i(0, LevelData.COLUMNS - 1))


func test_moving_brick_between_neighbors_stays_put() -> void:
	_stub("normal", Vector2i(4, 2))
	_stub("normal", Vector2i(6, 2))
	assert_eq(MovingBehavior.free_span(_grid, Vector2i(5, 2)), Vector2i(5, 5))


func test_moving_brick_moves_and_stays_in_range() -> void:
	_stub("steel", Vector2i(2, 0))
	_stub("steel", Vector2i(6, 0))
	var moving := _brick("moving", Vector2i(4, 0))
	add_child_autofree(moving)
	var min_x := 3 * _grid.cell_step.x
	var max_x := 5 * _grid.cell_step.x
	var seen_min := INF
	var seen_max := -INF
	for i in 180:
		await wait_physics_frames(1)
		seen_min = minf(seen_min, moving.position.x)
		seen_max = maxf(seen_max, moving.position.x)
	assert_gt(seen_max - seen_min, 10.0, "it moves")
	assert_true(seen_min >= min_x - 0.01 and seen_max <= max_x + 0.01, "it stays in its span")


# --- portal ---

func test_portals_pair_in_reading_order() -> void:
	var a := _stub("portal", Vector2i(10, 0))
	var b := _stub("portal", Vector2i(2, 1))
	var c := _stub("portal", Vector2i(5, 3))
	var d := _stub("portal", Vector2i(1, 0))
	var portals: Array[Brick] = [a, b, c, d]
	# reading order: d (1,0), a (10,0), b (2,1), c (5,3) -> pairs d-a and b-c
	assert_eq(PortalBehavior.partner_of(portals, d), a)
	assert_eq(PortalBehavior.partner_of(portals, a), d)
	assert_eq(PortalBehavior.partner_of(portals, b), c)
	assert_eq(PortalBehavior.partner_of(portals, c), b)


func test_odd_portal_pairs_with_the_first() -> void:
	var a := _stub("portal", Vector2i(0, 0))
	var b := _stub("portal", Vector2i(1, 0))
	var c := _stub("portal", Vector2i(2, 0))
	var portals: Array[Brick] = [a, b, c]
	assert_eq(PortalBehavior.partner_of(portals, c), a)


func test_lone_portal_has_no_partner() -> void:
	var a := _stub("portal", Vector2i(0, 0))
	var portals: Array[Brick] = [a]
	assert_null(PortalBehavior.partner_of(portals, a))


func test_portal_exit_clears_the_portal_on_a_diagonal() -> void:
	# Regression: on a diagonal the ball used to come out still touching the partner, hit it
	# again and bounce between the two portals forever.
	var partner := _stub("portal", Vector2i(0, 0))
	partner.size = Vector2(64.8, 20)
	partner.global_position = Vector2(56, 320)
	var radius := 8.0
	for angle in [-15.0, -38.0, -60.0, -85.0, 20.0, 140.0, -160.0]:
		var direction := Vector2.from_angle(deg_to_rad(angle))
		var exit := PortalBehavior.exit_position(partner, direction, radius)
		var rect := Rect2(partner.global_position - partner.size / 2.0, partner.size)
		var closest := exit.clamp(rect.position, rect.end)
		assert_gt(exit.distance_to(closest), radius, "angle %s: ball clear of the portal" % angle)


func test_portal_exit_is_outside_on_the_far_side() -> void:
	var partner := _stub("portal", Vector2i(0, 0))
	partner.size = Vector2(64, 20)
	partner.global_position = Vector2(500, 300)
	var exit := PortalBehavior.exit_position(partner, Vector2.UP, 8.0)
	assert_lt(exit.y, 300.0 - 10.0 - 8.0, "above the portal, clear of it")
	assert_almost_eq(exit.x, 500.0, 0.01)


# --- spawner ---

func test_spawner_finds_free_neighbors() -> void:
	_stub("normal", Vector2i(4, 4))
	_stub("normal", Vector2i(5, 4))
	var free := SpawnerBehavior.free_neighbors(_grid, Vector2i(4, 5))
	assert_eq(free.size(), 6, "8 around minus the 2 bricks above")
	assert_false(Vector2i(4, 4) in free)


func test_spawner_in_a_corner() -> void:
	assert_eq(SpawnerBehavior.free_neighbors(_grid, Vector2i(0, 0)).size(), 3)


# --- grid helpers ---

func test_grid_bounds() -> void:
	assert_true(_grid.in_bounds(Vector2i(0, 0)))
	assert_true(_grid.in_bounds(Vector2i(17, 19)))
	assert_false(_grid.in_bounds(Vector2i(18, 0)))
	assert_false(_grid.in_bounds(Vector2i(0, -1)))
