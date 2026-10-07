extends GutTest

## Unit tests for LevelParser: valid levels, defaults and every kind of validation error.

func before_all() -> void:
	# Messages are translated; the assertions below check the English text.
	TranslationServer.set_locale("en")


const EMPTY_ROW := ".................."
const NORMAL_ROW := "nnnnnnnnnnnnnnnnnn"
const MIXED_ROW := "..nhSnnnnnnnnnShn.."

var _types: Dictionary[String, BrickType] = {}


func before_each() -> void:
	_types = {
		"normal": _type("normal", 1, true),
		"hard2": _type("hard2", 2, true),
		"steel": _type("steel", BrickType.INDESTRUCTIBLE, false),
	}


func _type(id: String, hp: int, counts: bool) -> BrickType:
	var t := BrickType.new()
	t.id = id
	t.hp = hp
	t.counts_for_clear = counts
	return t


## A minimal valid level; tests change one thing at a time.
func _level() -> Dictionary:
	return {
		"format_version": 1,
		"name": "Test",
		"author": "Pero",
		"columns": 18,
		"legend": {".": null, "n": "normal", "h": "hard2", "S": "steel"},
		"grid": [EMPTY_ROW, NORMAL_ROW],
	}


func _parse(data: Dictionary) -> LevelParser.Result:
	return LevelParser.parse(JSON.stringify(data), _types)


func _assert_error(result: LevelParser.Result, fragment: String) -> void:
	assert_false(result.is_ok(), "should fail")
	assert_null(result.level, "no level on failure")
	var found := false
	for e in result.errors:
		if fragment in e:
			found = true
	assert_true(found, "expected an error containing '%s', got %s" % [fragment, result.errors])


# --- valid levels ---

func test_valid_level_parses() -> void:
	var result := _parse(_level())
	assert_true(result.is_ok(), str(result.errors))
	assert_eq(result.level.name, "Test")
	assert_eq(result.level.author, "Pero")
	assert_eq(result.level.row_count(), 2)


func test_cells_map_symbols_to_ids() -> void:
	var data := _level()
	data.grid = ["nhS..............."]
	var level := _parse(data).level
	assert_eq(level.cell(0, 0), "normal")
	assert_eq(level.cell(0, 1), "hard2")
	assert_eq(level.cell(0, 2), "steel")
	assert_eq(level.cell(0, 3), "", "null in legend = empty cell")


func test_missing_settings_use_defaults() -> void:
	var level := _parse(_level()).level
	assert_eq(level.ball_speed, 1.0)
	assert_eq(level.drop_modifier, 1.0)
	assert_eq(level.allowed_powerups, "all")
	assert_eq(level.banned_powerups.size(), 0)


func test_settings_are_read() -> void:
	var data := _level()
	data.settings = {
		"ball_speed": 1.25, "drop_modifier": 0.5, "allowed_powerups": ["multiball", "laser"],
		"banned_powerups": ["skip_level"], "background": "space_01", "music": "track_02",
	}
	var level := _parse(data).level
	assert_eq(level.ball_speed, 1.25)
	assert_eq(level.drop_modifier, 0.5)
	assert_eq(level.allowed_powerups, PackedStringArray(["multiball", "laser"]))
	assert_eq(level.banned_powerups, PackedStringArray(["skip_level"]))
	assert_eq(level.background, "space_01")
	assert_eq(level.music, "track_02")


func test_twenty_rows_is_allowed() -> void:
	var data := _level()
	var grid: Array = []
	for i in 20:
		grid.append(NORMAL_ROW)
	data.grid = grid
	assert_true(_parse(data).is_ok())


func test_unknown_top_level_keys_are_ignored() -> void:
	var data := _level()
	data["editor_notes"] = "something from a newer editor"
	assert_true(_parse(data).is_ok())


# --- errors ---

func test_invalid_json() -> void:
	_assert_error(LevelParser.parse("{ \"name\": ", _types), "Invalid JSON")


func test_root_must_be_object() -> void:
	_assert_error(LevelParser.parse("[1, 2, 3]", _types), "must be a JSON object")


func test_missing_format_version() -> void:
	var data := _level()
	data.erase("format_version")
	_assert_error(_parse(data), "format_version")


func test_newer_format_version_is_rejected() -> void:
	var data := _level()
	data.format_version = 2
	_assert_error(_parse(data), "Unsupported format_version 2")


func test_missing_name() -> void:
	var data := _level()
	data.name = "  "
	_assert_error(_parse(data), "\"name\"")


func test_wrong_column_count() -> void:
	var data := _level()
	data.columns = 13
	_assert_error(_parse(data), "\"columns\" must be 18")


func test_row_with_wrong_length() -> void:
	var data := _level()
	data.grid = [NORMAL_ROW, "nnnn"]
	_assert_error(_parse(data), "Row 2 has 4 characters")


func test_symbol_not_in_legend() -> void:
	var data := _level()
	data.grid = ["nnnnnXnnnnnnnnnnnn"]
	_assert_error(_parse(data), "Row 1, column 6: \"X\" is not in the legend")


func test_unknown_brick_type_is_reported_once() -> void:
	var data := _level()
	data.legend["L"] = "laser_brick"
	data.grid = ["LLLLLLnnnnnnnnnnnn"]
	var result := _parse(data)
	_assert_error(result, "unknown brick type \"laser_brick\"")
	assert_eq(result.errors.size(), 1, "grid cells must not repeat the legend error")


func test_too_many_rows() -> void:
	var data := _level()
	var grid: Array = []
	for i in 21:
		grid.append(NORMAL_ROW)
	data.grid = grid
	_assert_error(_parse(data), "21 rows")


func test_empty_grid() -> void:
	var data := _level()
	data.grid = []
	_assert_error(_parse(data), "\"grid\"")


func test_level_with_only_steel_cannot_be_cleared() -> void:
	var data := _level()
	data.grid = ["SSSSSSSSSSSSSSSSSS"]
	_assert_error(_parse(data), "no bricks that must be broken")


func test_invalid_ball_speed() -> void:
	var data := _level()
	data.settings = {"ball_speed": 0}
	_assert_error(_parse(data), "ball_speed")


func test_invalid_allowed_powerups() -> void:
	var data := _level()
	data.settings = {"allowed_powerups": "some"}
	_assert_error(_parse(data), "allowed_powerups")


func test_all_errors_are_collected() -> void:
	var data := _level()
	data.erase("name")
	data.columns = 10
	data.settings = {"ball_speed": -1}
	var result := _parse(data)
	assert_eq(result.errors.size(), 3, str(result.errors))
