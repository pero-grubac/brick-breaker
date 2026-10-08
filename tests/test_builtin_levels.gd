extends GutTest

## Every built-in level set and every level in it must load without errors.


func test_there_is_at_least_one_builtin_set() -> void:
	assert_gt(LevelLoader.find_sets(LevelLoader.BUILTIN_SETS_DIR).size(), 0)


func test_every_builtin_level_loads() -> void:
	for level_set in LevelLoader.find_sets(LevelLoader.BUILTIN_SETS_DIR):
		for i in level_set.level_count():
			var result := LevelLoader.load_level(level_set, i)
			assert_true(result.is_ok(), "%s #%d: %s" % [level_set.id, i + 1, result.errors])


func test_builtin_set_ids_are_unique() -> void:
	var seen: Dictionary[String, bool] = {}
	for level_set in LevelLoader.find_sets(LevelLoader.BUILTIN_SETS_DIR):
		assert_false(seen.has(level_set.id), "duplicate set id " + level_set.id)
		seen[level_set.id] = true


func test_classic_set_has_at_least_30_levels() -> void:
	var result := LevelLoader.load_set("res://levels/classic")
	assert_true(result.is_ok())
	assert_gte(result.level_set.level_count(), 30)


func test_every_brick_type_appears_in_the_classic_set() -> void:
	var classic := LevelLoader.load_set("res://levels/classic").level_set
	var used: Dictionary[String, bool] = {}
	for i in classic.level_count():
		var level := LevelLoader.load_level(classic, i).level
		for row in level.cells:
			for id in row:
				used[id] = true
	for id in ["normal", "hard2", "hard3", "steel", "tnt", "bonus", "ghost", "moving", "regen",
			"portal", "spawner"]:
		assert_true(used.has(id), id + " is used in some level")
