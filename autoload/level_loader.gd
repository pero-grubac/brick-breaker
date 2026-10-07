extends Node

## The only place that reads and writes level files. Holds the brick type catalog, loads level
## sets for the game, and saves, exports and imports the player's sets for the editor.
## Registered as the `LevelLoader` autoload. Parsing and validation live in LevelParser /
## LevelSetParser and LevelSerializer; this class does the file access.

const BRICKS_DIR: String = "res://data/bricks"
const BUILTIN_SETS_DIR: String = "res://levels"
const USER_SETS_DIR: String = "user://levelsets"

## Every known brick type, by id.
var brick_types: Dictionary[String, BrickType] = {}


## Outcome of an import: the new set (saved under user://levelsets), or errors.
class ImportResult:
	var level_set: LevelSetData = null
	var errors: PackedStringArray = []
	## Levels that were skipped because they are broken (the rest was imported).
	var skipped: PackedStringArray = []

	func is_ok() -> bool:
		return level_set != null


func _ready() -> void:
	_load_brick_types()


func get_brick_type(id: String) -> BrickType:
	return brick_types.get(id)


## Loads the manifest of the set in `dir_path`. Errors are prefixed with the file path.
func load_set(dir_path: String) -> LevelSetParser.Result:
	var path := dir_path.path_join(LevelSetData.MANIFEST_FILE)
	var text: Variant = _read_text(path)
	var result: LevelSetParser.Result
	if text == null:
		result = LevelSetParser.Result.new()
		result.errors.append("Cannot read file")
	else:
		result = LevelSetParser.parse(text)
	if result.is_ok():
		result.level_set.dir_path = dir_path
	_prefix_errors(result.errors, path)
	return result


## Loads every valid set in a folder (one subfolder per set). Broken sets are skipped with
## a warning, so one bad download never hides the others.
func find_sets(root_dir: String) -> Array[LevelSetData]:
	var sets: Array[LevelSetData] = []
	if not DirAccess.dir_exists_absolute(root_dir):
		return sets
	var folders := DirAccess.get_directories_at(root_dir)
	folders.sort()
	for folder in folders:
		var result := load_set(root_dir.path_join(folder))
		if result.is_ok():
			sets.append(result.level_set)
		else:
			push_warning("Skipping level set: " + "; ".join(result.errors))
	return sets


## Built-in sets first, then the player's own sets.
func find_all_sets() -> Array[LevelSetData]:
	var sets := find_sets(BUILTIN_SETS_DIR)
	sets.append_array(find_sets(USER_SETS_DIR))
	return sets


## Loads and validates one level of a set. Never crashes: problems come back as errors.
func load_level(level_set: LevelSetData, index: int) -> LevelParser.Result:
	var path := level_set.level_path(index)
	var text: Variant = _read_text(path)
	var result: LevelParser.Result
	if text == null:
		result = LevelParser.Result.new()
		result.errors.append("Cannot read file")
	else:
		result = LevelParser.parse(text, brick_types)
	_prefix_errors(result.errors, path)
	return result


## Every valid level of a set, in order. Broken levels are skipped with a warning.
func load_all_levels(level_set: LevelSetData) -> Array[LevelData]:
	var levels: Array[LevelData] = []
	for i in level_set.level_count():
		var result := load_level(level_set, i)
		if result.is_ok():
			levels.append(result.level)
		else:
			push_warning("; ".join(result.errors))
	return levels


## A new, empty player set in its own folder under `root` (not written until save_set).
func create_set(set_name: String, author: String = "", description: String = "",
		root: String = USER_SETS_DIR) -> LevelSetData:
	var level_set := LevelSetData.new()
	var folder := _unique_folder(root, _slug(set_name))
	level_set.id = "custom." + folder
	level_set.name = set_name
	level_set.author = author
	level_set.description = description
	level_set.dir_path = root.path_join(folder)
	return level_set


## Validates and writes a set: levels as 01.json, 02.json... plus set.json. Nothing is written
## if any level is invalid; the errors say which level and why.
func save_set(level_set: LevelSetData, levels: Array[LevelData]) -> PackedStringArray:
	var errors := PackedStringArray()
	if level_set.name.strip_edges().is_empty():
		errors.append("Set name is empty")
	if levels.is_empty():
		errors.append("A set needs at least one level")
	var texts: Array[String] = []
	for i in levels.size():
		var text := LevelSerializer.level_to_json(levels[i])
		var check := LevelParser.parse(text, brick_types)
		for error in check.errors:
			errors.append("Level %d: %s" % [i + 1, error])
		texts.append(text)
	if not errors.is_empty():
		return errors

	var err := DirAccess.make_dir_recursive_absolute(level_set.dir_path)
	if err != OK:
		errors.append("Cannot create folder %s: %s" % [level_set.dir_path, error_string(err)])
		return errors
	var files := PackedStringArray()
	for i in texts.size():
		var file := "%02d.json" % (i + 1)
		files.append(file)
		err = _write_text(level_set.dir_path.path_join(file), texts[i])
		if err != OK:
			errors.append("Cannot write %s: %s" % [file, error_string(err)])
			return errors
	# Remove level files that are no longer part of the set.
	for old in DirAccess.get_files_at(level_set.dir_path):
		if old.ends_with(".json") and old != LevelSetData.MANIFEST_FILE and not old in files:
			DirAccess.remove_absolute(level_set.dir_path.path_join(old))
	level_set.level_files = files
	err = _write_text(level_set.dir_path.path_join(LevelSetData.MANIFEST_FILE),
			LevelSerializer.set_to_json(level_set))
	if err != OK:
		errors.append("Cannot write set.json: " + error_string(err))
	return errors


## Deletes a player set and its folder. Built-in sets cannot be deleted.
func delete_set(level_set: LevelSetData) -> Error:
	if level_set.dir_path.begins_with("res://"):
		return ERR_UNAUTHORIZED
	for file in DirAccess.get_files_at(level_set.dir_path):
		DirAccess.remove_absolute(level_set.dir_path.path_join(file))
	return DirAccess.remove_absolute(level_set.dir_path)


## Writes the set (set.json + level files) into a .zip, inside one folder.
func export_set_zip(level_set: LevelSetData, zip_path: String) -> Error:
	var zip := ZIPPacker.new()
	var err := zip.open(zip_path)
	if err != OK:
		return err
	var folder := level_set.dir_path.get_file()
	var files := PackedStringArray([LevelSetData.MANIFEST_FILE])
	files.append_array(level_set.level_files)
	for file in files:
		var bytes := FileAccess.get_file_as_bytes(level_set.dir_path.path_join(file))
		zip.start_file(folder.path_join(file))
		zip.write_file(bytes)
		zip.close_file()
	return zip.close()


## Writes one level as a standalone .json file.
func export_level_json(level: LevelData, path: String) -> Error:
	return _write_text(path, LevelSerializer.level_to_json(level))


## Imports a .zip, a set folder, a set.json or a single level .json as a new player set.
func import_path(path: String, root: String = USER_SETS_DIR) -> ImportResult:
	var result := ImportResult.new()
	var manifest_text: Variant = null
	var level_texts: Dictionary[String, Variant] = {}
	var extension := path.get_extension().to_lower()
	if extension == "zip":
		var reader := ZIPReader.new()
		var err := reader.open(path)
		if err != OK:
			result.errors.append("Cannot open %s: %s" % [path.get_file(), error_string(err)])
			return result
		var prefix: Variant = _zip_set_prefix(reader.get_files())
		if prefix == null:
			reader.close()
			result.errors.append("%s has no set.json" % path.get_file())
			return result
		var manifest_entry := (prefix as String) + LevelSetData.MANIFEST_FILE
		manifest_text = reader.read_file(manifest_entry).get_string_from_utf8()
		for entry in reader.get_files():
			if entry.begins_with(prefix) and entry.ends_with(".json"):
				var name_in_set := entry.trim_prefix(prefix)
				level_texts[name_in_set] = reader.read_file(entry).get_string_from_utf8()
		reader.close()
	elif DirAccess.dir_exists_absolute(path) or path.get_file() == LevelSetData.MANIFEST_FILE:
		var dir := path if DirAccess.dir_exists_absolute(path) else path.get_base_dir()
		manifest_text = _read_text(dir.path_join(LevelSetData.MANIFEST_FILE))
		if manifest_text == null:
			result.errors.append("%s has no set.json" % dir)
			return result
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".json"):
				level_texts[file] = _read_text(dir.path_join(file))
	elif extension == "json":
		return _import_single_level(path, root)
	else:
		result.errors.append("%s: use a .zip, a folder or a .json file" % path.get_file())
		return result

	var manifest := LevelSetParser.parse(manifest_text)
	if not manifest.is_ok():
		for error in manifest.errors:
			result.errors.append("set.json: " + error)
		return result
	var source := manifest.level_set
	var levels: Array[LevelData] = []
	for file in source.level_files:
		var text: Variant = level_texts.get(file)
		if text == null:
			result.skipped.append("%s: missing" % file)
			continue
		var parsed := LevelParser.parse(text, brick_types)
		if parsed.is_ok():
			levels.append(parsed.level)
		else:
			result.skipped.append("%s: %s" % [file, parsed.errors[0]])
	if levels.is_empty():
		result.errors.append("No valid levels in the set")
		result.errors.append_array(result.skipped)
		return result
	var level_set := create_set(source.name, source.author, source.description, root)
	var save_errors := save_set(level_set, levels)
	if not save_errors.is_empty():
		result.errors = save_errors
		return result
	result.level_set = level_set
	return result


func _import_single_level(path: String, root: String) -> ImportResult:
	var result := ImportResult.new()
	var text: Variant = _read_text(path)
	if text == null:
		result.errors.append("Cannot read " + path.get_file())
		return result
	var parsed := LevelParser.parse(text, brick_types)
	if not parsed.is_ok():
		for error in parsed.errors:
			result.errors.append("%s: %s" % [path.get_file(), error])
		return result
	var level_set := create_set(parsed.level.name, parsed.level.author, "", root)
	var levels: Array[LevelData] = [parsed.level]
	var save_errors := save_set(level_set, levels)
	if not save_errors.is_empty():
		result.errors = save_errors
		return result
	result.level_set = level_set
	return result


## Folder inside the zip that holds set.json ("" for the zip root), or null if there is none.
func _zip_set_prefix(entries: PackedStringArray) -> Variant:
	var best: Variant = null
	for entry in entries:
		if entry.get_file() == LevelSetData.MANIFEST_FILE:
			var prefix := entry.trim_suffix(LevelSetData.MANIFEST_FILE)
			if best == null or prefix.length() < (best as String).length():
				best = prefix
	return best


## "My Cool Set!" -> "my-cool-set"
func _slug(text: String) -> String:
	var slug := ""
	for c in text.to_lower():
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			slug += c
		elif not slug.ends_with("-"):
			slug += "-"
	slug = slug.trim_prefix("-").trim_suffix("-")
	return slug if not slug.is_empty() else "set"


func _unique_folder(root: String, base: String) -> String:
	var folder := base
	var n := 2
	while DirAccess.dir_exists_absolute(root.path_join(folder)):
		folder = "%s-%d" % [base, n]
		n += 1
	return folder


func _write_text(path: String, text: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.close()
	return OK


func _load_brick_types() -> void:
	brick_types.clear()
	# list_directory() also sees resources that were remapped or converted in an exported game.
	for file in ResourceLoader.list_directory(BRICKS_DIR):
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var path := BRICKS_DIR.path_join(file)
		var brick_type := load(path) as BrickType
		if brick_type == null or brick_type.id.is_empty():
			push_error("Not a valid BrickType: " + path)
		elif brick_types.has(brick_type.id):
			push_error("Duplicate brick type id \"%s\" in %s" % [brick_type.id, path])
		else:
			brick_types[brick_type.id] = brick_type


## Returns the file contents, or null if the file cannot be read.
func _read_text(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return file.get_as_text()


func _prefix_errors(errors: PackedStringArray, path: String) -> void:
	for i in errors.size():
		errors[i] = "%s: %s" % [path, errors[i]]
