extends GutTest

## Tests for the stage E2 power-up effects, run against a fake Game behind GameContext.

const BRICK_SCENE: PackedScene = preload("res://scenes/game/brick.tscn")
const PADDLE_SCENE: PackedScene = preload("res://scenes/game/paddle.tscn")


## Records what effects ask Game to do.
class FakeGame extends Node:
	var bricks: Array[Brick] = []
	var balls: Array[Ball] = []
	var spawned: Array[Vector2] = []
	var score_multiplier: float = 1.0
	var radius_factor: float = 1.0
	var combo_lock: bool = false
	var lives_lost: int = 0
	var levels_completed: int = 0

	func ctx_bricks() -> Array[Brick]:
		return bricks

	func ctx_balls() -> Array[Ball]:
		return balls

	func ctx_spawn_ball(_position: Vector2, direction: Vector2) -> Ball:
		spawned.append(direction)
		return null

	func ctx_multiply_score(factor: float) -> void:
		score_multiplier *= factor

	func ctx_set_ball_radius_factor(factor: float) -> void:
		radius_factor = factor

	func ctx_set_combo_lock(enabled: bool) -> void:
		combo_lock = enabled

	func ctx_lose_life() -> void:
		lives_lost += 1

	func ctx_complete_level() -> void:
		levels_completed += 1


var _game: FakeGame
var _ctx: GameContext


func before_each() -> void:
	_game = autofree(FakeGame.new())
	var paddle: Paddle = autofree(PADDLE_SCENE.instantiate())
	_ctx = GameContext.new(_game, paddle)


func _brick(id: String) -> Brick:
	var brick: Brick = BRICK_SCENE.instantiate()
	brick.brick_type = LevelLoader.get_brick_type(id)
	add_child_autofree(brick)
	_game.bricks.append(brick)
	return brick


func test_points_x2_stacks_and_undoes() -> void:
	var first := PointsX2Effect.new()
	var second := PointsX2Effect.new()
	first.apply(_ctx)
	second.apply(_ctx)
	assert_eq(_game.score_multiplier, 4.0)
	first.remove(_ctx)
	second.remove(_ctx)
	assert_eq(_game.score_multiplier, 1.0)


func test_big_and_small_ball_set_and_reset_radius() -> void:
	var big := BigBallEffect.new()
	big.apply(_ctx)
	assert_gt(_game.radius_factor, 1.0)
	big.remove(_ctx)
	assert_eq(_game.radius_factor, 1.0)
	var small := SmallBallEffect.new()
	small.apply(_ctx)
	assert_lt(_game.radius_factor, 1.0)


func test_combo_lock_toggles() -> void:
	var lock := ComboLockEffect.new()
	lock.apply(_ctx)
	assert_true(_game.combo_lock)
	lock.remove(_ctx)
	assert_false(_game.combo_lock)


func test_weaken_hits_only_bricks_with_two_or_more_hp() -> void:
	var normal := _brick("normal")
	var hard := _brick("hard3")
	var steel := _brick("steel")
	WeakenEffect.new().apply(_ctx)
	assert_false(normal.is_destroyed(), "one-hit bricks are left alone")
	assert_eq(hard.hp, 2)
	assert_false(steel.is_destroyed())


func test_fortify_adds_at_most_one_hp_over_type() -> void:
	var normal := _brick("normal")
	var steel := _brick("steel")
	FortifyEffect.new().apply(_ctx)
	FortifyEffect.new().apply(_ctx)
	assert_eq(normal.hp, normal.brick_type.hp + 1)
	assert_eq(steel.hp, steel.brick_type.hp, "indestructible bricks do not change")


func test_lightning_destroys_six_clearable_bricks() -> void:
	var targets: Array[Brick] = []
	for i in 10:
		targets.append(_brick("normal"))
	var steel := _brick("steel")
	LightningEffect.new().apply(_ctx)
	var destroyed := targets.filter(func(b: Brick) -> bool: return b.is_destroyed()).size()
	assert_eq(destroyed, LightningEffect.STRIKES)
	assert_false(steel.is_destroyed())


func test_lightning_with_few_bricks_destroys_them_all() -> void:
	var a := _brick("normal")
	var b := _brick("hard2")
	LightningEffect.new().apply(_ctx)
	assert_true(a.is_destroyed())
	assert_true(b.is_destroyed())


func test_mega_ball_fills_up_to_total() -> void:
	var ball: Ball = autofree(Ball.new())
	_game.balls = [ball, ball, ball]
	MegaBallEffect.new().apply(_ctx)
	assert_eq(_game.spawned.size(), MegaBallEffect.TOTAL_BALLS - 3)
	for direction in _game.spawned:
		assert_lt(direction.y, 0.0, "new balls fly upwards")


func test_mega_ball_without_flying_balls_does_nothing() -> void:
	MegaBallEffect.new().apply(_ctx)
	assert_eq(_game.spawned.size(), 0)


func test_death_and_skip_level_call_game() -> void:
	DeathEffect.new().apply(_ctx)
	SkipLevelEffect.new().apply(_ctx)
	assert_eq(_game.lives_lost, 1)
	assert_eq(_game.levels_completed, 1)
