extends GutTest

## Unit tests for DropSelector: drop chance, candidate filtering and the weighted pick.

const EPSILON := 0.0001


func _def(id: String, weight: float = 1.0, negative: bool = false) -> PowerUpDef:
	var d := PowerUpDef.new()
	d.id = id
	d.weight = weight
	d.is_negative = negative
	return d


func _ids(defs: Array[PowerUpDef]) -> PackedStringArray:
	var ids := PackedStringArray()
	for d in defs:
		ids.append(d.id)
	return ids


# --- drop_chance ---

func test_chance_is_brick_times_level_at_combo_x1() -> void:
	assert_almost_eq(DropSelector.drop_chance(0.1, 1.5, 1.0), 0.15, EPSILON)


func test_combo_adds_2_percent_per_step() -> void:
	# x2.0 = 2 steps above x1
	assert_almost_eq(DropSelector.drop_chance(0.1, 1.0, 2.0), 0.14, EPSILON)


func test_no_drops_stay_no_drops_with_combo() -> void:
	assert_eq(DropSelector.drop_chance(0.0, 1.0, 5.0), 0.0, "steel never drops")
	assert_eq(DropSelector.drop_chance(0.1, 0.0, 5.0), 0.0, "level with drop_modifier 0")


func test_chance_is_capped_at_1() -> void:
	assert_eq(DropSelector.drop_chance(0.9, 2.0, 5.0), 1.0)


func test_should_drop() -> void:
	assert_true(DropSelector.should_drop(0.25, 0.1))
	assert_false(DropSelector.should_drop(0.25, 0.25))
	assert_false(DropSelector.should_drop(0.0, 0.0))
	assert_true(DropSelector.should_drop(1.0, 0.999))


# --- candidates ---

func test_all_allows_everything() -> void:
	var defs: Array[PowerUpDef] = [_def("a"), _def("b")]
	assert_eq(_ids(DropSelector.candidates(defs, "all", [])), PackedStringArray(["a", "b"]))


func test_allowed_list_limits_candidates() -> void:
	var defs: Array[PowerUpDef] = [_def("a"), _def("b"), _def("c")]
	var allowed := PackedStringArray(["a", "c"])
	assert_eq(_ids(DropSelector.candidates(defs, allowed, [])), PackedStringArray(["a", "c"]))


func test_banned_wins_over_allowed() -> void:
	var defs: Array[PowerUpDef] = [_def("a"), _def("b")]
	var allowed := PackedStringArray(["a", "b"])
	assert_eq(_ids(DropSelector.candidates(defs, allowed, PackedStringArray(["b"]))),
			PackedStringArray(["a"]))


func test_positive_only_skips_negative() -> void:
	var defs: Array[PowerUpDef] = [_def("good"), _def("bad", 1.0, true)]
	assert_eq(_ids(DropSelector.candidates(defs, "all", [], true)), PackedStringArray(["good"]))


func test_zero_weight_is_never_a_candidate() -> void:
	var defs: Array[PowerUpDef] = [_def("a", 0.0), _def("b")]
	assert_eq(_ids(DropSelector.candidates(defs, "all", [])), PackedStringArray(["b"]))


# --- pick ---

func test_pick_by_weight_ranges() -> void:
	# a: [0, 0.25), b: [0.25, 1.0) of the total
	var defs: Array[PowerUpDef] = [_def("a", 1.0), _def("b", 3.0)]
	assert_eq(DropSelector.pick(defs, 0.0).id, "a")
	assert_eq(DropSelector.pick(defs, 0.24).id, "a")
	assert_eq(DropSelector.pick(defs, 0.25).id, "b")
	assert_eq(DropSelector.pick(defs, 0.99).id, "b")


func test_pick_with_roll_1_returns_last() -> void:
	var defs: Array[PowerUpDef] = [_def("a"), _def("b")]
	assert_eq(DropSelector.pick(defs, 1.0).id, "b")


func test_pick_from_nothing_is_null() -> void:
	var defs: Array[PowerUpDef] = []
	assert_null(DropSelector.pick(defs, 0.5))


func test_pick_distribution_follows_weights() -> void:
	var defs: Array[PowerUpDef] = [_def("a", 1.0), _def("b", 3.0)]
	var counts := {"a": 0, "b": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in 4000:
		counts[DropSelector.pick(defs, rng.randf()).id] += 1
	assert_almost_eq(counts["b"] / 4000.0, 0.75, 0.03)
