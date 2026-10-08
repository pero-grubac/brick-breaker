extends GutTest

## WebFiles helpers that also work outside the browser (the temporary files).


func test_write_temp_round_trip() -> void:
	var bytes := PackedByteArray([1, 2, 3, 250])
	var path := WebFiles.write_temp("some/dir/level.json", bytes)
	assert_eq(path, WebFiles.TEMP_DIR.path_join("level.json"), "only the file name is kept")
	assert_eq(FileAccess.get_file_as_bytes(path), bytes)
	DirAccess.remove_absolute(path)


func test_not_available_outside_the_browser() -> void:
	assert_false(WebFiles.available())
