class_name SaveData
extends RefCounted

## Everything the game remembers between runs: settings and progress per level set.
## Pure data + rules (no file access, see SaveManager), so it is easy to unit test.
##
## Unlock rule (user decision): level 1 is always a valid start; any other level becomes a
## valid start once the player has cleared it.

const VERSION: int = 1
const DEFAULT_VOLUME: float = 0.8

# Settings
var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME
## Locale code ("en", "sr_Latn"); empty = not chosen yet.
var language: String = ""
var fullscreen: bool = false
## Retro CRT scanline overlay.
var crt: bool = true

## set_id -> {"cleared": Array of level indices, "best_score": int}
var _progress: Dictionary = {}


func is_level_cleared(set_id: String, index: int) -> bool:
	return index in _set_progress(set_id).cleared


func mark_cleared(set_id: String, index: int) -> void:
	var p := _set_progress(set_id)
	if not index in p.cleared:
		p.cleared.append(index)
		p.cleared.sort()


## Level indices the player may start from, ascending; always includes 0.
func selectable_starts(set_id: String, level_count: int) -> Array[int]:
	var starts: Array[int] = [0]
	for index: int in _set_progress(set_id).cleared:
		if index > 0 and index < level_count and not index in starts:
			starts.append(index)
	starts.sort()
	return starts


func is_selectable_start(set_id: String, index: int, level_count: int) -> bool:
	return index in selectable_starts(set_id, level_count)


func best_score(set_id: String) -> int:
	return _set_progress(set_id).best_score


## Records a finished run. Returns true if it is a new best for the set.
func submit_score(set_id: String, score: int) -> bool:
	var p := _set_progress(set_id)
	if score <= p.best_score:
		return false
	p.best_score = score
	return true


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"settings": {
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"language": language,
			"fullscreen": fullscreen,
			"crt": crt,
		},
		"progress": _progress.duplicate(true),
	}


## Builds SaveData from a parsed save file. Missing or wrong values fall back to defaults,
## so an old or damaged save never stops the game.
static func from_dict(data: Variant) -> SaveData:
	var save := SaveData.new()
	if not data is Dictionary:
		return save
	var settings: Variant = data.get("settings", {})
	if settings is Dictionary:
		save.music_volume = _volume(settings.get("music_volume"), save.music_volume)
		save.sfx_volume = _volume(settings.get("sfx_volume"), save.sfx_volume)
		var language: Variant = settings.get("language")
		if language is String:
			save.language = language
		var fullscreen: Variant = settings.get("fullscreen")
		if fullscreen is bool:
			save.fullscreen = fullscreen
		var crt: Variant = settings.get("crt")
		if crt is bool:
			save.crt = crt
	var progress: Variant = data.get("progress", {})
	if progress is Dictionary:
		for set_id: Variant in progress:
			var entry: Variant = progress[set_id]
			if not set_id is String or not entry is Dictionary:
				continue
			var p := save._set_progress(set_id)
			var cleared: Variant = entry.get("cleared", [])
			if cleared is Array:
				for index: Variant in cleared:
					if (index is int or index is float) and int(index) >= 0:
						save.mark_cleared(set_id, int(index))
			var best: Variant = entry.get("best_score", 0)
			if (best is int or best is float) and int(best) > 0:
				p.best_score = int(best)
	return save


static func _volume(value: Variant, fallback: float) -> float:
	if value is int or value is float:
		return clampf(float(value), 0.0, 1.0)
	return fallback


func _set_progress(set_id: String) -> Dictionary:
	if not _progress.has(set_id):
		_progress[set_id] = {"cleared": [], "best_score": 0}
	return _progress[set_id]
