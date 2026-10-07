extends GutTest

## Integration tests for the LevelLoader autoload, using the files in res://tests/fixtures/sets.

const FIXTURES := "res://tests/fixtures/sets"


func test_brick_catalog_is_loaded() -> void:
	for id in ["normal", "normal_red", "hard2", "hard3", "steel", "tnt"]:
		assert_not_null(LevelLoader.get_brick_type(id), "brick type %s" % id)
	assert_null(LevelLoader.get_brick_type("does_not_exist"))


func test_catalog_ids_match_their_data() -> void:
	var steel := LevelLoader.get_brick_type("steel")
	assert_eq(steel.hp, BrickType.INDESTRUCTIBLE)
	assert_false(steel.counts_for_clear)


func test_load_set_reads_manifest() -> void:
	var result := LevelLoader.load_set(FIXTURES.path_join("good"))
	assert_true(result.is_ok(), str(result.errors))
	assert_eq(result.level_set.id, "test.good")
	assert_eq(result.level_set.level_count(), 4)
	assert_eq(result.level_set.dir_path, FIXTURES.path_join("good"))


func test_load_set_without_manifest_fails_cleanly() -> void:
	var result := LevelLoader.load_set(FIXTURES.path_join("no_manifest"))
	assert_false(result.is_ok())
	assert_string_contains(result.errors[0], "Cannot read file")


func test_find_sets_skips_broken_sets() -> void:
	var sets := LevelLoader.find_sets(FIXTURES)
	assert_eq(sets.size(), 1, "only the good set is valid")
	assert_eq(sets[0].id, "test.good")


func test_find_sets_in_missing_folder_is_empty() -> void:
	assert_eq(LevelLoader.find_sets("user://does_not_exist").size(), 0)


func test_load_valid_level() -> void:
	var level_set := LevelLoader.load_set(FIXTURES.path_join("good")).level_set
	var result := LevelLoader.load_level(level_set, 0)
	assert_true(result.is_ok(), str(result.errors))
	assert_eq(result.level.name, "Fixture Level")
	assert_eq(result.level.row_count(), 3)
	assert_eq(result.level.cell(1, 2), "normal")
	assert_eq(result.level.ball_speed, 1.2)


func test_level_with_unknown_brick_reports_file_and_reason() -> void:
	var level_set := LevelLoader.load_set(FIXTURES.path_join("good")).level_set
	var result := LevelLoader.load_level(level_set, 1)
	assert_false(result.is_ok())
	assert_string_contains(result.errors[0], "unknown_brick.json")
	assert_string_contains(result.errors[0], "laser_brick")


func test_broken_json_level_does_not_crash() -> void:
	var level_set := LevelLoader.load_set(FIXTURES.path_join("good")).level_set
	var result := LevelLoader.load_level(level_set, 2)
	assert_false(result.is_ok())
	assert_string_contains(result.errors[0], "Invalid JSON")


func test_missing_level_file_does_not_crash() -> void:
	var level_set := LevelLoader.load_set(FIXTURES.path_join("good")).level_set
	var result := LevelLoader.load_level(level_set, 3)
	assert_false(result.is_ok())
	assert_string_contains(result.errors[0], "missing.json: Cannot read file")
