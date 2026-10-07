extends GutTest

## Integration tests for LevelLoader writing: save, reload, delete, export and import.
## Everything happens in a temporary folder under user:// that is removed after each test.

const ROOT := "user://gut_tmp_levelsets"
const EXPORTS := "user://gut_tmp_exports"


func after_each() -> void:
	_remove_tree(ROOT)
	_remove_tree(EXPORTS)


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for dir in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(dir))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


func _level(level_name: String, brick: String = "normal") -> LevelData:
	var level := LevelData.create_empty(level_name)
	for c in LevelData.COLUMNS:
		level.set_cell(1, c, brick)
	return level


func _saved_set(set_name: String, count: int) -> LevelSetData:
	var level_set := LevelLoader.create_set(set_name, "Tests", "desc", ROOT)
	var levels: Array[LevelData] = []
	for i in count:
		levels.append(_level("L%d" % (i + 1)))
	assert_eq(LevelLoader.save_set(level_set, levels), PackedStringArray())
	return level_set


func test_save_and_reload() -> void:
	var saved := _saved_set("My Set", 3)
	var loaded := LevelLoader.load_set(saved.dir_path)
	assert_true(loaded.is_ok(), str(loaded.errors))
	assert_eq(loaded.level_set.name, "My Set")
	assert_eq(loaded.level_set.level_count(), 3)
	var levels := LevelLoader.load_all_levels(loaded.level_set)
	assert_eq(levels[2].name, "L3")


func test_folder_names_are_unique() -> void:
	var a := _saved_set("Same Name", 1)
	var b := _saved_set("Same Name", 1)
	assert_ne(a.dir_path, b.dir_path)
	assert_ne(a.id, b.id)
	assert_eq(LevelLoader.find_sets(ROOT).size(), 2)


func test_saving_fewer_levels_removes_old_files() -> void:
	var level_set := _saved_set("Shrink", 3)
	var levels: Array[LevelData] = [_level("Only")]
	assert_eq(LevelLoader.save_set(level_set, levels), PackedStringArray())
	var json_files := 0
	for file in DirAccess.get_files_at(level_set.dir_path):
		if file.ends_with(".json"):
			json_files += 1
	assert_eq(json_files, 2, "set.json + 01.json")


func test_invalid_level_is_not_saved() -> void:
	var level_set := LevelLoader.create_set("Bad", "", "", ROOT)
	var empty := LevelData.create_empty("Empty level")  # no bricks to break
	var levels: Array[LevelData] = [_level("Fine"), empty]
	var errors := LevelLoader.save_set(level_set, levels)
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "Level 2")
	assert_false(DirAccess.dir_exists_absolute(level_set.dir_path), "nothing written")


func test_delete_set() -> void:
	var level_set := _saved_set("Doomed", 2)
	assert_eq(LevelLoader.delete_set(level_set), OK)
	assert_false(DirAccess.dir_exists_absolute(level_set.dir_path))


func test_builtin_set_cannot_be_deleted() -> void:
	var classic := LevelLoader.load_set("res://levels/classic").level_set
	assert_eq(LevelLoader.delete_set(classic), ERR_UNAUTHORIZED)


func test_zip_export_and_import() -> void:
	var original := _saved_set("Zip Me", 2)
	DirAccess.make_dir_recursive_absolute(EXPORTS)
	var zip_path := EXPORTS.path_join("zip-me.zip")
	assert_eq(LevelLoader.export_set_zip(original, zip_path), OK)
	var imported := LevelLoader.import_path(zip_path, ROOT)
	assert_true(imported.is_ok(), str(imported.errors))
	assert_eq(imported.level_set.name, "Zip Me")
	assert_eq(imported.level_set.level_count(), 2)
	assert_ne(imported.level_set.dir_path, original.dir_path, "imported as a new set")


func test_builtin_set_can_be_exported_and_imported() -> void:
	var classic := LevelLoader.load_set("res://levels/classic").level_set
	DirAccess.make_dir_recursive_absolute(EXPORTS)
	var zip_path := EXPORTS.path_join("classic.zip")
	assert_eq(LevelLoader.export_set_zip(classic, zip_path), OK)
	var imported := LevelLoader.import_path(zip_path, ROOT)
	assert_true(imported.is_ok(), str(imported.errors))
	assert_eq(imported.level_set.level_count(), classic.level_count())


func test_folder_import() -> void:
	var original := _saved_set("Folder Set", 2)
	var imported := LevelLoader.import_path(original.dir_path, ROOT)
	assert_true(imported.is_ok(), str(imported.errors))
	assert_eq(imported.level_set.level_count(), 2)


func test_single_level_import_becomes_a_set() -> void:
	DirAccess.make_dir_recursive_absolute(EXPORTS)
	var path := EXPORTS.path_join("one.json")
	assert_eq(LevelLoader.export_level_json(_level("Solo Level"), path), OK)
	var imported := LevelLoader.import_path(path, ROOT)
	assert_true(imported.is_ok(), str(imported.errors))
	assert_eq(imported.level_set.name, "Solo Level")
	assert_eq(imported.level_set.level_count(), 1)


func test_import_skips_broken_levels() -> void:
	var imported := LevelLoader.import_path("res://tests/fixtures/sets/good", ROOT)
	assert_true(imported.is_ok(), str(imported.errors))
	assert_eq(imported.level_set.level_count(), 1, "only 01.json is valid")
	assert_eq(imported.skipped.size(), 3)


func test_import_of_broken_set_fails_cleanly() -> void:
	var imported := LevelLoader.import_path("res://tests/fixtures/sets/bad_manifest", ROOT)
	assert_false(imported.is_ok())
	assert_gt(imported.errors.size(), 0)


func test_import_of_unknown_file_type() -> void:
	var imported := LevelLoader.import_path("res://icon.svg", ROOT)
	assert_false(imported.is_ok())
