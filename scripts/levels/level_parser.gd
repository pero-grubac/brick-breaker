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
		result.errors.append(_t("ERR_INVALID_JSON")
				% [json.get_error_line(), json.get_error_message()])
		return result
	if not json.data is Dictionary:
		result.errors.append(_t("ERR_LEVEL_NOT_OBJECT"))
		return result
	return parse_dict(json.data, brick_types)


static func parse_dict(data: Dictionary, brick_types: Dictionary[String, BrickType]) -> Result:
	var result := Result.new()
	var errors := result.errors
	var level := LevelData.new()

	_check_format_version(data, errors)

	level.name = _read_string(data, "name", "", errors)
	if level.name.strip_edges().is_empty():
		errors.append(_t("ERR_FIELD_MISSING") % "name")
	level.author = _read_string(data, "author", "", errors)

	var columns: Variant = data.get("columns")
	if not _is_number(columns) or int(columns) != LevelData.COLUMNS:
		errors.append(_t("ERR_COLUMNS") % LevelData.COLUMNS)

	var legend := _read_legend(data, brick_types, errors)
	_read_grid(data, legend, level, errors)
	if errors.is_empty() and not _has_clearable_brick(level, brick_types):
		errors.append(_t("ERR_NOTHING_TO_CLEAR"))

	_read_settings(data, level, errors)

	if errors.is_empty():
		result.level = level
	return result


static func _check_format_version(data: Dictionary, errors: PackedStringArray) -> void:
	var version: Variant = data.get("format_version")
	if not _is_number(version):
		errors.append(_t("ERR_FORMAT_VERSION_MISSING"))
	elif int(version) < 1 or int(version) > LevelData.FORMAT_VERSION:
		errors.append(_t("ERR_FORMAT_VERSION_UNSUPPORTED")
				% [int(version), LevelData.FORMAT_VERSION])


## Returns symbol -> brick id ("" for an empty cell).
static func _read_legend(data: Dictionary, brick_types: Dictionary[String, BrickType],
		errors: PackedStringArray) -> Dictionary[String, String]:
	var legend: Dictionary[String, String] = {}
	var raw: Variant = data.get("legend")
	if not raw is Dictionary:
		errors.append(_t("ERR_LEGEND_NOT_OBJECT"))
		return legend
	for symbol: Variant in raw:
		var id: Variant = raw[symbol]
		if not symbol is String or (symbol as String).length() != 1:
			errors.append(_t("ERR_LEGEND_KEY") % symbol)
		elif id == null:
			legend[symbol] = ""
		elif not id is String:
			errors.append(_t("ERR_LEGEND_VALUE") % symbol)
			legend[symbol] = ""  # already reported; keep grid cells from repeating the error
		elif not brick_types.has(id):
			errors.append(_t("ERR_UNKNOWN_BRICK") % [symbol, id])
			legend[symbol] = ""
		else:
			legend[symbol] = id
	return legend


static func _read_grid(data: Dictionary, legend: Dictionary[String, String], level: LevelData,
		errors: PackedStringArray) -> void:
	var raw: Variant = data.get("grid")
	if not raw is Array or (raw as Array).is_empty():
		errors.append(_t("ERR_GRID_EMPTY"))
		return
	var rows: Array = raw
	if rows.size() > LevelData.MAX_ROWS:
		errors.append(_t("ERR_GRID_TOO_MANY") % [rows.size(), LevelData.MAX_ROWS])
		return
	for r in rows.size():
		var row: Variant = rows[r]
		if not row is String:
			errors.append(_t("ERR_ROW_NOT_STRING") % (r + 1))
			continue
		var text: String = row
		if text.length() != LevelData.COLUMNS:
			errors.append(_t("ERR_ROW_LENGTH")
					% [r + 1, text.length(), LevelData.COLUMNS])
			continue
		var ids := PackedStringArray()
		for c in text.length():
			var symbol := text[c]
			if not legend.has(symbol):
				errors.append(_t("ERR_SYMBOL_UNKNOWN") % [r + 1, c + 1, symbol])
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
		errors.append(_t("ERR_SETTINGS_NOT_OBJECT"))
		return
	var settings: Dictionary = raw

	var ball_speed: Variant = settings.get("ball_speed", level.ball_speed)
	if not _is_number(ball_speed) or float(ball_speed) <= 0.0:
		errors.append(_t("ERR_BALL_SPEED"))
	else:
		level.ball_speed = float(ball_speed)

	var drop_modifier: Variant = settings.get("drop_modifier", level.drop_modifier)
	if not _is_number(drop_modifier) or float(drop_modifier) < 0.0:
		errors.append(_t("ERR_DROP_MODIFIER"))
	else:
		level.drop_modifier = float(drop_modifier)

	var allowed: Variant = settings.get("allowed_powerups", "all")
	if allowed is String and allowed == "all":
		level.allowed_powerups = "all"
	elif _is_string_list(allowed):
		level.allowed_powerups = PackedStringArray(allowed)
	else:
		errors.append(_t("ERR_ALLOWED_POWERUPS"))

	var banned: Variant = settings.get("banned_powerups", [])
	if _is_string_list(banned):
		level.banned_powerups = PackedStringArray(banned)
	else:
		errors.append(_t("ERR_BANNED_POWERUPS"))

	level.background = _read_string(settings, "background", "", errors, "settings.")
	level.music = _read_string(settings, "music", "", errors, "settings.")


static func _read_string(data: Dictionary, key: String, default: String,
		errors: PackedStringArray, prefix: String = "") -> String:
	var value: Variant = data.get(key, default)
	if value is String:
		return value
	errors.append(_t("ERR_NOT_STRING") % (prefix + key))
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


## Error text in the current language (keys live in i18n/strings.csv).
static func _t(key: String) -> String:
	return String(TranslationServer.translate(key))
