class_name LevelSetParser
extends RefCounted

## Turns set.json text into a LevelSetData, or a list of readable errors. Pure logic like
## LevelParser; LevelLoader does the file access and fills in `dir_path`.


class Result:
	var level_set: LevelSetData = null
	var errors: PackedStringArray = []

	func is_ok() -> bool:
		return errors.is_empty()


static func parse(json_text: String) -> Result:
	var result := Result.new()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		result.errors.append("Invalid JSON at line %d: %s"
				% [json.get_error_line(), json.get_error_message()])
		return result
	if not json.data is Dictionary:
		result.errors.append("set.json must be a JSON object")
		return result

	var data: Dictionary = json.data
	var errors := result.errors
	var level_set := LevelSetData.new()

	var version: Variant = data.get("format_version")
	if not (version is int or version is float):
		errors.append("\"format_version\" is missing")
	elif int(version) < 1 or int(version) > LevelSetData.FORMAT_VERSION:
		errors.append("Unsupported format_version %d (this game reads up to %d)"
				% [int(version), LevelSetData.FORMAT_VERSION])

	level_set.id = _required_string(data, "id", errors)
	level_set.name = _required_string(data, "name", errors)
	level_set.author = _optional_string(data, "author", errors)
	level_set.description = _optional_string(data, "description", errors)

	var levels: Variant = data.get("levels")
	if not levels is Array or (levels as Array).is_empty():
		errors.append("\"levels\" must be a non-empty list of file names")
	else:
		for i in (levels as Array).size():
			var file: Variant = levels[i]
			if not file is String or not _is_plain_json_file_name(file):
				errors.append("Level %d: \"%s\" must be a .json file name in the set folder"
						% [i + 1, file])
			else:
				level_set.level_files.append(file)

	if errors.is_empty():
		result.level_set = level_set
	return result


## Only plain file names: no folders, no "..", so a downloaded set cannot point outside itself.
static func _is_plain_json_file_name(file: String) -> bool:
	return file.ends_with(".json") and file.length() > 5 \
			and not "/" in file and not "\\" in file and not ".." in file


static func _required_string(data: Dictionary, key: String, errors: PackedStringArray) -> String:
	var value: Variant = data.get(key)
	if not value is String or (value as String).strip_edges().is_empty():
		errors.append("\"%s\" is missing or empty" % key)
		return ""
	return value


static func _optional_string(data: Dictionary, key: String, errors: PackedStringArray) -> String:
	var value: Variant = data.get(key, "")
	if not value is String:
		errors.append("\"%s\" must be a string" % key)
		return ""
	return value
