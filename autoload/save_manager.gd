extends Node

## The only place that writes progress and settings (user://save.json). Registered as the
## `SaveManager` autoload. Listens to EventBus for cleared levels and finished runs, and applies
## settings (volume, language, fullscreen) to the engine.

signal settings_changed

const SAVE_PATH: String = "user://save.json"
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"
const DEFAULT_LOCALE: String = "en"
const LOCALES: PackedStringArray = ["en", "sr_Latn"]

var data: SaveData = SaveData.new()
## False = keep everything in memory only. Test harnesses turn this off so simulations never
## touch the player's real save file.
var persist: bool = true


func _ready() -> void:
	data = _load()
	if data.language.is_empty():
		data.language = _system_locale()
	apply_settings()
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.run_ended.connect(_on_run_ended)


## Pushes the current settings to the engine and remembers them.
func apply_settings() -> void:
	_set_bus_volume(MUSIC_BUS, data.music_volume if data.music_on else 0.0)
	_set_bus_volume(SFX_BUS, data.sfx_volume if data.sfx_on else 0.0)
	TranslationServer.set_locale(data.language)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if data.fullscreen \
			else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode and not OS.has_feature("web"):
		DisplayServer.window_set_mode(mode)
	settings_changed.emit()


func save() -> void:
	if not persist:
		return
	# Write to a temporary file first, so a crash mid-write never destroys the old save.
	var tmp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save: " + error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data.to_dict(), "  "))
	file.close()
	var err := DirAccess.rename_absolute(tmp_path, SAVE_PATH)
	if err != OK:
		push_error("Cannot replace save: " + error_string(err))


func _load() -> SaveData:
	if not FileAccess.file_exists(SAVE_PATH):
		return SaveData.new()
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		# Keep the broken file for inspection and start fresh.
		push_warning("Save file is damaged, starting with a new one")
		DirAccess.rename_absolute(SAVE_PATH, SAVE_PATH + ".broken")
		return SaveData.new()
	return SaveData.from_dict(parsed)


func _on_level_completed(set_id: String, level_index: int) -> void:
	data.mark_cleared(set_id, level_index)
	save()


func _on_run_ended(set_id: String, score: int) -> void:
	if data.submit_score(set_id, score):
		save()


func _set_bus_volume(bus_name: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(volume))
	AudioServer.set_bus_mute(index, volume <= 0.0)


func _system_locale() -> String:
	var system := OS.get_locale_language()
	if system in ["sr", "hr", "bs", "me", "sh"]:
		return "sr_Latn"
	return DEFAULT_LOCALE
