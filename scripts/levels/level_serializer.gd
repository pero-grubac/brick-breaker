class_name LevelSerializer
extends RefCounted

## The other direction of LevelParser / LevelSetParser: turns LevelData and LevelSetData into
## JSON text in the same format (format_version 1). Pure logic; LevelLoader writes the files.

## Readable symbols for the built-in brick types; other types get the next free character.
const PREFERRED_SYMBOLS: Dictionary[String, String] = {
	"normal": "b", "normal_red": "r", "normal_orange": "o", "normal_yellow": "y",
	"normal_green": "g", "normal_purple": "p", "hard2": "h", "hard3": "H", "steel": "S",
	"tnt": "T", "bonus": "B",
}
const SPARE_SYMBOLS: String = "acdefijklmnqstuvwxzACDEFGIJKLMNOPQRUVWXYZ0123456789*#+=@%&"
const EMPTY_SYMBOL: String = "."


static func level_to_dict(level: LevelData) -> Dictionary:
	var used_rows := maxi(level.used_row_count(), 1)
	var symbols := _assign_symbols(level, used_rows)
	var legend := {EMPTY_SYMBOL: null}
	for id in symbols:
		legend[symbols[id]] = id
	var grid: Array[String] = []
	for r in used_rows:
		var line := ""
		for id in level.cells[r]:
			line += EMPTY_SYMBOL if id.is_empty() else symbols[id]
		grid.append(line)
	var settings := {
		"ball_speed": level.ball_speed,
		"drop_modifier": level.drop_modifier,
		"allowed_powerups": level.allowed_powerups if level.allowed_powerups is String \
				else Array(level.allowed_powerups),
		"banned_powerups": Array(level.banned_powerups),
	}
	if not level.background.is_empty():
		settings["background"] = level.background
	if not level.music.is_empty():
		settings["music"] = level.music
	return {
		"format_version": LevelData.FORMAT_VERSION,
		"name": level.name,
		"author": level.author,
		"columns": LevelData.COLUMNS,
		"legend": legend,
		"grid": grid,
		"settings": settings,
	}


static func level_to_json(level: LevelData) -> String:
	return JSON.stringify(level_to_dict(level), "  ", false) + "\n"


static func set_to_json(level_set: LevelSetData) -> String:
	var data := {
		"format_version": LevelSetData.FORMAT_VERSION,
		"id": level_set.id,
		"name": level_set.name,
		"author": level_set.author,
		"description": level_set.description,
		"levels": Array(level_set.level_files),
	}
	return JSON.stringify(data, "  ", false) + "\n"


## Brick id -> one-character symbol, for the ids used in the first `rows` rows.
static func _assign_symbols(level: LevelData, rows: int) -> Dictionary[String, String]:
	var symbols: Dictionary[String, String] = {}
	var taken: Dictionary[String, bool] = {EMPTY_SYMBOL: true}
	var ids: Array[String] = []
	for r in rows:
		for id in level.cells[r]:
			if not id.is_empty() and not id in ids:
				ids.append(id)
	for id in ids:
		var preferred: String = PREFERRED_SYMBOLS.get(id, "")
		if not preferred.is_empty() and not taken.has(preferred):
			symbols[id] = preferred
			taken[preferred] = true
	var spare := 0
	for id in ids:
		if symbols.has(id):
			continue
		while taken.has(SPARE_SYMBOLS[spare]):
			spare += 1
		symbols[id] = SPARE_SYMBOLS[spare]
		taken[SPARE_SYMBOLS[spare]] = true
	return symbols
