class_name LevelParser
extends RefCounted

## Turns level JSON text into a LevelData, or a list of readable errors. Pure logic: no scenes
## and no file access (LevelLoader reads the files), so it is easy to unit test.


## Outcome of a parse: `level` is set only when `errors` is empty.
class Result:
	var level: LevelData = null
	var errors: PackedStringArray = []

	func is_ok() -> bool:
		return errors.is_empty()


## `brick_types` maps every known brick id to its BrickType.
static func parse(json_text: String, brick_types: Dictionary[String, BrickType]) -> Result:
	var result := Result.new()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		result.errors.append("Invalid JSON at line %d: %s"
				% [json.get_error_line(), json.get_error_message()])
		return result
	if not json.data is Dictionary:
		result.errors.append("Level must be a JSON object")
		return result
	return parse_dict(json.data, brick_types)


static func parse_dict(data: Dictionary, brick_types: Dictionary[String, BrickType]) -> Result:
	var result := Result.new()
	var errors := result.errors
	var level := LevelData.new()

	_check_format_version(data, errors)

	level.name = _read_string(data, "name", "", errors)
	if level.name.strip_edges().is_empty():
		errors.append("\"name\" is missing or empty")
	level.author = _read_string(data, "author", "", errors)

	var columns: Variant = data.get("columns")
	if not _is_number(columns) or int(columns) != LevelData.COLUMNS:
		errors.append("\"columns\" must be %d" % LevelData.COLUMNS)

	var legend := _read_legend(data, brick_types, errors)
	_read_grid(data, legend, level, errors)
	if errors.is_empty() and not _has_clearable_brick(level, brick_types):
		errors.append("Level has no bricks that must be broken to clear it")

	_read_settings(data, level, errors)

	if errors.is_empty():
		result.level = level
	return result


static func _check_format_version(data: Dictionary, errors: PackedStringArray) -> void:
	var version: Variant = data.get("format_version")
	if not _is_number(version):
		errors.append("\"format_version\" is missing")
	elif int(version) < 1 or int(version) > LevelData.FORMAT_VERSION:
		errors.append("Unsupported format_version %d (this game reads up to %d)"
				% [int(version), LevelData.FORMAT_VERSION])


## Returns symbol -> brick id ("" for an empty cell).
static func _read_legend(data: Dictionary, brick_types: Dictionary[String, BrickType],
		errors: PackedStringArray) -> Dictionary[String, String]:
	var legend: Dictionary[String, String] = {}
	var raw: Variant = data.get("legend")
	if not raw is Dictionary:
		errors.append("\"legend\" must be an object")
		return legend
	for symbol: Variant in raw:
		var id: Variant = raw[symbol]
		if not symbol is String or (symbol as String).length() != 1:
			errors.append("Legend key \"%s\" must be a single character" % symbol)
		elif id == null:
			legend[symbol] = ""
		elif not id is String:
			errors.append("Legend \"%s\" must map to a brick id or null" % symbol)
			legend[symbol] = ""  # already reported; keep grid cells from repeating the error
		elif not brick_types.has(id):
			errors.append("Legend \"%s\": unknown brick type \"%s\"" % [symbol, id])
			legend[symbol] = ""
		else:
			legend[symbol] = id
	return legend


static func _read_grid(data: Dictionary, legend: Dictionary[String, String], level: LevelData,
		errors: PackedStringArray) -> void:
	var raw: Variant = data.get("grid")
	if not raw is Array or (raw as Array).is_empty():
		errors.append("\"grid\" must be a non-empty list of rows")
		return
	var rows: Array = raw
	if rows.size() > LevelData.MAX_ROWS:
		errors.append("\"grid\" has %d rows, the maximum is %d" % [rows.size(), LevelData.MAX_ROWS])
		return
	for r in rows.size():
		var row: Variant = rows[r]
		if not row is String:
			errors.append("Row %d must be a string" % (r + 1))
			continue
		var text: String = row
		if text.length() != LevelData.COLUMNS:
			errors.append("Row %d has %d characters, expected %d"
					% [r + 1, text.length(), LevelData.COLUMNS])
			continue
		var ids := PackedStringArray()
		for c in text.length():
			var symbol := text[c]
			if not legend.has(symbol):
				errors.append("Row %d, column %d: \"%s\" is not in the legend" % [r + 1, c + 1, symbol])
				ids.append("")
			else:
				ids.append(legend[symbol])
		level.cells.append(ids)


static func _has_clearable_brick(level: LevelData,
		brick_types: Dictionary[String, BrickType]) -> bool:
	for row in level.cells:
		for id in row:
			if id != "" and brick_types[id].counts_for_clear:
				return true
	return false


static func _read_settings(data: Dictionary, level: LevelData, errors: PackedStringArray) -> void:
	var raw: Variant = data.get("settings", {})
	if not raw is Dictionary:
		errors.append("\"settings\" must be an object")
		return
	var settings: Dictionary = raw

	var ball_speed: Variant = settings.get("ball_speed", level.ball_speed)
	if not _is_number(ball_speed) or float(ball_speed) <= 0.0:
		errors.append("settings.ball_speed must be a number above 0")
	else:
		level.ball_speed = float(ball_speed)

	var drop_modifier: Variant = settings.get("drop_modifier", level.drop_modifier)
	if not _is_number(drop_modifier) or float(drop_modifier) < 0.0:
		errors.append("settings.drop_modifier must be a number, 0 or above")
	else:
		level.drop_modifier = float(drop_modifier)

	var allowed: Variant = settings.get("allowed_powerups", "all")
	if allowed is String and allowed == "all":
		level.allowed_powerups = "all"
	elif _is_string_list(allowed):
		level.allowed_powerups = PackedStringArray(allowed)
	else:
		errors.append("settings.allowed_powerups must be \"all\" or a list of ids")

	var banned: Variant = settings.get("banned_powerups", [])
	if _is_string_list(banned):
		level.banned_powerups = PackedStringArray(banned)
	else:
		errors.append("settings.banned_powerups must be a list of ids")

	level.background = _read_string(settings, "background", "", errors, "settings.")
	level.music = _read_string(settings, "music", "", errors, "settings.")


static func _read_string(data: Dictionary, key: String, default: String,
		errors: PackedStringArray, prefix: String = "") -> String:
	var value: Variant = data.get(key, default)
	if value is String:
		return value
	errors.append("%s%s must be a string" % [prefix, key])
	return default


## JSON numbers arrive as float in Godot; accept both int and float.
static func _is_number(value: Variant) -> bool:
	return value is int or value is float


static func _is_string_list(value: Variant) -> bool:
	if not value is Array:
		return false
	for item: Variant in value:
		if not item is String:
			return false
	return true
