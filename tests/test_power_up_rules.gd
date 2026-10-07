extends GutTest

## Unit tests for PowerUpRules: REFRESH, STACK, REPLACE, INSTANT and exclusive groups.

const R := PowerUpDef.StackRule


func _def(id: String, rule: PowerUpDef.StackRule, group: String = "") -> PowerUpDef:
	var d := PowerUpDef.new()
	d.id = id
	d.stack_rule = rule
	d.exclusive_group = group
	d.duration = 10.0
	return d


func _active(def: PowerUpDef) -> PowerUpEffect:
	var e := PowerUpEffect.new()
	e.def = def
	return e


func test_refresh_applies_when_not_active() -> void:
	var r := PowerUpRules.resolve([], _def("sticky", R.REFRESH))
	assert_true(r.apply_new)
	assert_null(r.refresh)
	assert_true(r.keep_active)


func test_refresh_restarts_the_active_one() -> void:
	var sticky := _def("sticky", R.REFRESH)
	var active: Array[PowerUpEffect] = [_active(sticky)]
	var r := PowerUpRules.resolve(active, sticky)
	assert_false(r.apply_new)
	assert_eq(r.refresh, active[0])
	assert_eq(r.remove.size(), 0)


func test_stack_always_adds() -> void:
	var points := _def("points_x2", R.STACK)
	var active: Array[PowerUpEffect] = [_active(points)]
	var r := PowerUpRules.resolve(active, points)
	assert_true(r.apply_new)
	assert_eq(r.remove.size(), 0)


func test_replace_removes_the_same_id_and_reapplies() -> void:
	var long_paddle := _def("long_paddle", R.REPLACE, "paddle_size")
	var active: Array[PowerUpEffect] = [_active(long_paddle)]
	var r := PowerUpRules.resolve(active, long_paddle)
	assert_eq(r.remove, active)
	assert_true(r.apply_new)


func test_replace_removes_the_rest_of_the_group() -> void:
	var long_paddle := _def("long_paddle", R.REPLACE, "paddle_size")
	var short_paddle := _def("short_paddle", R.REPLACE, "paddle_size")
	var slow := _def("slow_ball", R.REPLACE, "ball_speed")
	var active: Array[PowerUpEffect] = [_active(short_paddle), _active(slow)]
	var r := PowerUpRules.resolve(active, long_paddle)
	assert_eq(r.remove, [active[0]] as Array[PowerUpEffect], "short paddle goes, slow ball stays")
	assert_true(r.apply_new)


func test_group_is_exclusive_for_refresh_too() -> void:
	var fire := _def("fire_ball", R.REFRESH, "ball_type")
	var explosive := _def("explosive_ball", R.REFRESH, "ball_type")
	var active: Array[PowerUpEffect] = [_active(explosive)]
	var r := PowerUpRules.resolve(active, fire)
	assert_eq(r.remove, active)
	assert_true(r.apply_new)


func test_no_group_means_no_conflicts() -> void:
	var sticky := _def("sticky", R.REFRESH)
	var magnet := _def("magnet", R.REFRESH)
	var active: Array[PowerUpEffect] = [_active(magnet)]
	var r := PowerUpRules.resolve(active, sticky)
	assert_eq(r.remove.size(), 0)
	assert_true(r.apply_new)


func test_instant_applies_once_and_touches_nothing() -> void:
	var life := _def("extra_life", R.INSTANT, "")
	var other := _def("sticky", R.REFRESH)
	var active: Array[PowerUpEffect] = [_active(other)]
	var r := PowerUpRules.resolve(active, life)
	assert_true(r.apply_new)
	assert_false(r.keep_active)
	assert_eq(r.remove.size(), 0)
	assert_null(r.refresh)
