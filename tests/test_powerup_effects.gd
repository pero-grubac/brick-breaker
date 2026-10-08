extends GutTest

## Tests for the stage E2 and E3 power-up effects, run against a fake Game behind GameContext.

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
	var weapon: StringName = &""
	var ammo: int = -1
	var explosive: bool = false
	var shields: int = 0
	var magnet: bool = false
	var twin: bool = false

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

	func ctx_set_weapon(kind: StringName, shots: int) -> void:
		weapon = kind
		ammo = shots

	func ctx_weapon_ammo() -> int:
		return ammo

	func ctx_set_explosive(enabled: bool) -> void:
		explosive = enabled

	func ctx_add_shield() -> void:
		shields += 1

	func ctx_set_magnet(enabled: bool) -> void:
		magnet = enabled

	func ctx_set_twin_paddle(enabled: bool) -> void:
		twin = enabled


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


func test_laser_sets_and_clears_weapon() -> void:
	var laser := LaserEffect.new()
	laser.apply(_ctx)
	assert_eq(_game.weapon, &"laser")
	assert_eq(_game.ammo, -1, "laser has no ammo limit")
	laser.remove(_ctx)
	assert_eq(_game.weapon, &"")


func test_missile_ends_when_out_of_ammo() -> void:
	var missile := MissileEffect.new()
	missile.time_left = 20.0
	missile.apply(_ctx)
	assert_eq(_game.weapon, &"missile")
	assert_eq(_game.ammo, MissileEffect.AMMO)
	missile.tick(_ctx, 0.1)
	assert_gt(missile.time_left, 0.0, "still has missiles")
	_game.ammo = 0
	missile.tick(_ctx, 0.1)
	assert_eq(missile.time_left, 0.0)


func test_explosive_magnet_and_twin_toggle() -> void:
	var effects: Array[PowerUpEffect] = [ExplosiveBallEffect.new(), MagnetEffect.new(),
			TwinPaddleEffect.new()]
	for effect in effects:
		effect.apply(_ctx)
	assert_true(_game.explosive and _game.magnet and _game.twin)
	for effect in effects:
		effect.remove(_ctx)
	assert_false(_game.explosive or _game.magnet or _game.twin)


func test_shield_power_up_adds_a_shield() -> void:
	ShieldEffect.new().apply(_ctx)
	assert_eq(_game.shields, 1)


func test_shield_breaks_after_its_hits() -> void:
	var shield: Shield = Shield.new()
	add_child_autofree(shield)
	shield.add_hit()
	assert_eq(shield.hits, 2)
	shield.absorb(Vector2.ZERO)
	assert_false(shield.is_queued_for_deletion())
	shield.absorb(Vector2.ZERO)
	assert_true(shield.is_queued_for_deletion())
	assert_eq(shield.collision_layer, 0, "a broken shield stops colliding at once")


func test_shield_hits_are_capped() -> void:
	var shield: Shield = Shield.new()
	add_child_autofree(shield)
	for i in 5:
		shield.add_hit()
	assert_eq(shield.hits, Shield.MAX_HITS)
