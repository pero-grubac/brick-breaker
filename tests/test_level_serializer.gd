extends GutTest

## Unit tests for LevelSerializer: what it writes must read back as the same level.


func _types() -> Dictionary[String, BrickType]:
	return LevelLoader.brick_types


func _level() -> LevelData:
	var level := LevelData.create_empty("Round Trip")
	level.author = "Tests"
	level.set_cell(0, 0, "normal_red")
	level.set_cell(0, 17, "steel")
	level.set_cell(2, 5, "tnt")
	level.set_cell(3, 8, "hard3")
	level.ball_speed = 1.15
	level.drop_modifier = 0.5
	level.allowed_powerups = PackedStringArray(["multiball", "fire_ball"])
	level.banned_powerups = PackedStringArray(["fast_ball"])
	return level


func _round_trip(level: LevelData) -> LevelData:
	var result := LevelParser.parse(LevelSerializer.level_to_json(level), _types())
	assert_true(result.is_ok(), str(result.errors))
	return result.level


func test_round_trip_keeps_cells() -> void:
	var back := _round_trip(_level())
	assert_eq(back.cell(0, 0), "normal_red")
	assert_eq(back.cell(0, 17), "steel")
	assert_eq(back.cell(2, 5), "tnt")
	assert_eq(back.cell(3, 8), "hard3")
	assert_eq(back.cell(1, 1), "")


func test_round_trip_keeps_metadata_and_settings() -> void:
	var back := _round_trip(_level())
	assert_eq(back.name, "Round Trip")
	assert_eq(back.author, "Tests")
	assert_almost_eq(back.ball_speed, 1.15, 0.0001)
	assert_almost_eq(back.drop_modifier, 0.5, 0.0001)
	assert_eq(back.allowed_powerups, PackedStringArray(["multiball", "fire_ball"]))
	assert_eq(back.banned_powerups, PackedStringArray(["fast_ball"]))


func test_trailing_empty_rows_are_not_written() -> void:
	var data := LevelSerializer.level_to_dict(_level())
	assert_eq((data.grid as Array).size(), 4, "last brick is in row 4")


func test_leading_empty_rows_are_kept() -> void:
	var level := LevelData.create_empty("Gap")
	level.set_cell(5, 3, "normal")
	var back := _round_trip(level)
	assert_eq(back.row_count(), 6)
	assert_eq(back.cell(5, 3), "normal")


func test_builtin_types_get_readable_symbols() -> void:
	var data := LevelSerializer.level_to_dict(_level())
	assert_eq(data.legend["r"], "normal_red")
	assert_eq(data.legend["S"], "steel")
	assert_eq(data.legend["T"], "tnt")
	assert_eq(data.legend["."], null)


func test_rows_have_18_characters() -> void:
	for row: String in LevelSerializer.level_to_dict(_level()).grid:
		assert_eq(row.length(), LevelData.COLUMNS)


func test_builtin_levels_survive_a_round_trip() -> void:
	var classic := LevelLoader.load_set("res://levels/classic").level_set
	for i in classic.level_count():
		var original := LevelLoader.load_level(classic, i).level
		var back := _round_trip(original)
		assert_eq(back.cells, original.cells, "level %d" % (i + 1))
		assert_eq(back.name, original.name)


func test_set_json_round_trip() -> void:
	var s := LevelSetData.new()
	s.id = "custom.test"
	s.name = "Test Set"
	s.author = "Pero"
	s.description = "Opis sa šđčćž"
	s.level_files = PackedStringArray(["01.json", "02.json"])
	var back := LevelSetParser.parse(LevelSerializer.set_to_json(s))
	assert_true(back.is_ok(), str(back.errors))
	assert_eq(back.level_set.description, "Opis sa šđčćž")
	assert_eq(back.level_set.level_files, s.level_files)


func test_duplicate_level_is_independent() -> void:
	var a := _level()
	var b := a.duplicate_level()
	b.set_cell(0, 0, "")
	b.banned_powerups.append("x")
	assert_eq(a.cell(0, 0), "normal_red")
	assert_eq(a.banned_powerups.size(), 1)
