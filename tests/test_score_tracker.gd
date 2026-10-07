extends GutTest

## Unit tests for ScoreTracker: points, combo growth and cap, combo reset, extra lives.

var _t: ScoreTracker


func before_each() -> void:
	_t = ScoreTracker.new()


func test_starts_at_zero_with_combo_x1() -> void:
	assert_eq(_t.score, 0)
	assert_eq(_t.combo, 1.0)


func test_first_bricks_score_at_x1() -> void:
	_t.add_brick(50)
	_t.add_brick(50)
	assert_eq(_t.score, 100)
	assert_eq(_t.combo, 1.0)


func test_combo_grows_every_3_bricks() -> void:
	for i in 3:
		_t.add_brick(50)
	assert_eq(_t.combo, 1.5)
	for i in 3:
		_t.add_brick(50)
	assert_eq(_t.combo, 2.0)


func test_points_use_combo_before_the_brick_raises_it() -> void:
	for i in 3:
		_t.add_brick(100)  # 100 + 100 + 100, then combo becomes x1.5
	assert_eq(_t.score, 300)
	_t.add_brick(100)  # at x1.5
	assert_eq(_t.score, 450)


func test_combo_is_capped_at_x5() -> void:
	for i in 100:
		_t.add_brick(10)
	assert_eq(_t.combo, ScoreTracker.COMBO_MAX)


func test_combo_reaches_x5_after_24_bricks() -> void:
	for i in 23:
		_t.add_brick(10)
	assert_eq(_t.combo, 4.5)
	_t.add_brick(10)
	assert_eq(_t.combo, 5.0)


func test_reset_combo() -> void:
	for i in 7:
		_t.add_brick(50)
	_t.reset_combo()
	assert_eq(_t.combo, 1.0)
	_t.add_brick(50)
	_t.add_brick(50)
	assert_eq(_t.combo, 1.0, "counting starts over after a reset")


func test_points_are_rounded() -> void:
	for i in 3:
		_t.add_brick(1)
	_t.add_brick(1)  # 1 x 1.5 = 1.5 -> 2
	assert_eq(_t.score, 5)


func test_extra_life_at_50000() -> void:
	_t.score = 49950
	assert_eq(_t.add_brick(50), 1)
	assert_eq(_t.next_extra_life_at, 100000)


func test_no_extra_life_below_threshold() -> void:
	assert_eq(_t.add_brick(50), 0)


func test_two_thresholds_at_once_give_two_lives() -> void:
	_t.score = 49999
	assert_eq(_t.add_brick(50001), 2)
	assert_eq(_t.next_extra_life_at, 150000)


func test_extra_life_is_given_only_once_per_threshold() -> void:
	_t.score = 49950
	_t.add_brick(50)
	assert_eq(_t.add_brick(50), 0)
