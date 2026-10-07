extends Node

## The only place that reads level files. Holds the brick type catalog and loads level sets
## and levels for the game (and later the editor). Registered as the `LevelLoader` autoload.
## Parsing and validation live in LevelParser / LevelSetParser; this class does the file access.

const BRICKS_DIR: String = "res://data/bricks"
const BUILTIN_SETS_DIR: String = "res://levels"
const USER_SETS_DIR: String = "user://levelsets"

## Every known brick type, by id.
var brick_types: Dictionary[String, BrickType] = {}


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
