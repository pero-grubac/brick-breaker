extends GutTest

## Unit tests for LevelSetParser (set.json manifests).


func _manifest() -> Dictionary:
	return {
		"format_version": 1,
		"id": "pero.classic-pack",
		"name": "Classic Pack",
		"author": "Pero",
		"description": "Test set",
		"levels": ["01.json", "02.json"],
	}


func _parse(data: Variant) -> LevelSetParser.Result:
	return LevelSetParser.parse(JSON.stringify(data))


func _assert_error(result: LevelSetParser.Result, fragment: String) -> void:
	assert_false(result.is_ok(), "should fail")
	assert_null(result.level_set, "no set on failure")
	var found := false
	for e in result.errors:
		if fragment in e:
			found = true
	assert_true(found, "expected an error containing '%s', got %s" % [fragment, result.errors])


func test_valid_manifest_parses() -> void:
	var result := _parse(_manifest())
	assert_true(result.is_ok(), str(result.errors))
	var s := result.level_set
	assert_eq(s.id, "pero.classic-pack")
	assert_eq(s.name, "Classic Pack")
	assert_eq(s.author, "Pero")
	assert_eq(s.level_files, PackedStringArray(["01.json", "02.json"]))


func test_author_and_description_are_optional() -> void:
	var data := _manifest()
	data.erase("author")
	data.erase("description")
	assert_true(_parse(data).is_ok())


func test_level_path_joins_folder_and_file() -> void:
	var s := _parse(_manifest()).level_set
	s.dir_path = "res://levels/classic"
	assert_eq(s.level_path(1), "res://levels/classic/02.json")


func test_invalid_json() -> void:
	_assert_error(LevelSetParser.parse("{ \"id\": "), "Invalid JSON")


func test_missing_id() -> void:
	var data := _manifest()
	data.erase("id")
	_assert_error(_parse(data), "\"id\"")


func test_unsupported_version() -> void:
	var data := _manifest()
	data.format_version = 5
	_assert_error(_parse(data), "Unsupported format_version 5")


func test_empty_level_list() -> void:
	var data := _manifest()
	data.levels = []
	_assert_error(_parse(data), "\"levels\"")


func test_level_must_be_json_file() -> void:
	var data := _manifest()
	data.levels = ["01.txt"]
	_assert_error(_parse(data), "Level 1")


func test_level_cannot_leave_the_set_folder() -> void:
	for bad in ["../other/01.json", "sub/01.json", "C:\\levels\\01.json", "..json"]:
		var data := _manifest()
		data.levels = [bad]
		assert_false(_parse(data).is_ok(), "\"%s\" must be rejected" % bad)
