extends GutTest

## The power-up catalog in res://data/powerups must be complete and consistent.

const DIR := "res://data/powerups"

var _defs: Array[PowerUpDef] = []


func before_all() -> void:
	for file in ResourceLoader.list_directory(DIR):
		if file.ends_with(".tres"):
			_defs.append(load(DIR.path_join(file)) as PowerUpDef)


func test_expected_power_ups_exist() -> void:
	var ids := PackedStringArray()
	for d in _defs:
		ids.append(d.id)
	for id in ["multiball", "long_paddle", "short_paddle", "slow_ball", "fast_ball",
			"extra_life", "sticky_paddle", "fire_ball", "big_ball", "small_ball", "slow_motion",
			"points_x2", "combo_lock", "weaken", "fortify", "death", "skip_level", "mega_ball",
			"lightning"]:
		assert_true(id in ids, id)


func test_every_power_up_has_an_icon_and_translation() -> void:
	TranslationServer.set_locale("en")
	for d in _defs:
		assert_true(PowerUpIcons.has_icon(d.id), d.id + " icon")
		assert_ne(tr(d.display_name), d.display_name, d.id + " translation")


func test_ids_are_unique() -> void:
	var seen: Dictionary[String, bool] = {}
	for d in _defs:
		assert_false(seen.has(d.id), "duplicate id " + d.id)
		seen[d.id] = true


func test_every_def_is_complete() -> void:
	for d in _defs:
		assert_ne(d.display_name, "", d.id + " display_name")
		assert_ne(d.short_label, "", d.id + " short_label")
		assert_gt(d.weight, 0.0, d.id + " weight")
		assert_not_null(d.effect, d.id + " effect")
		assert_true(d.effect.new() is PowerUpEffect, d.id + " effect extends PowerUpEffect")


func test_instant_power_ups_have_no_duration() -> void:
	for d in _defs:
		if d.stack_rule == PowerUpDef.StackRule.INSTANT:
			assert_eq(d.duration, 0.0, d.id)


func test_negative_weight_stays_below_positive() -> void:
	# DESIGN.md: negative power-ups add excitement, but their total weight stays below positives.
	var positive := 0.0
	var negative := 0.0
	for d in _defs:
		if d.is_negative:
			negative += d.weight
		else:
			positive += d.weight
	assert_lt(negative, positive)


func test_bonus_brick_drops_only_positive() -> void:
	var bonus := LevelLoader.get_brick_type("bonus")
	assert_not_null(bonus)
	assert_eq(bonus.drop_chance, 1.0)
	assert_true(bonus.drop_positive_only)
