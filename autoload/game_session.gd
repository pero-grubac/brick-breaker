extends Node

## What the player chose in the menus (which set, which start level), the level editor's
## working state, and the scene changes between menus, editor and game. Registered as the
## `GameSession` autoload; it lives across scene changes.

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const SET_SELECT_SCENE: String = "res://scenes/menu/set_select.tscn"
const SETTINGS_SCENE: String = "res://scenes/menu/settings_menu.tscn"
const EDITOR_HUB_SCENE: String = "res://scenes/editor/editor_hub.tscn"
const LEVEL_EDITOR_SCENE: String = "res://scenes/editor/level_editor.tscn"
const GAME_SCENE: String = "res://scenes/game/game.tscn"

## Set and start level for the next game. Null = the game scene was started directly (F6 in
## the editor), so it uses its own exported values.
var level_set: LevelSetData = null
var start_level: int = 0

## Level played with "Test" from the editor (null = a normal game).
var test_level: LevelData = null

# Level editor working state: survives the trip to the game scene and back ("Test").
var editor_set: LevelSetData = null
var editor_levels: Array[LevelData] = []
var editor_index: int = 0
var editor_dirty: bool = false


func play(chosen_set: LevelSetData, chosen_start: int) -> void:
	level_set = chosen_set
	start_level = chosen_start
	test_level = null
	_change_scene(GAME_SCENE)


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)


func go_to_set_select() -> void:
	_change_scene(SET_SELECT_SCENE)


func go_to_settings() -> void:
	_change_scene(SETTINGS_SCENE)


func go_to_editor_hub() -> void:
	editor_set = null
	editor_levels.clear()
	_change_scene(EDITOR_HUB_SCENE)


## Opens the level editor on a set; `levels` are edited in memory until saved.
func open_level_editor(edited_set: LevelSetData, levels: Array[LevelData], index: int = 0) -> void:
	editor_set = edited_set
	editor_levels = levels
	editor_index = index
	editor_dirty = false
	_change_scene(LEVEL_EDITOR_SCENE)


## Plays one level from the editor; the editor state stays in this session.
func test_from_editor(level: LevelData) -> void:
	test_level = level.duplicate_level()
	_change_scene(GAME_SCENE)


func back_to_level_editor() -> void:
	test_level = null
	_change_scene(LEVEL_EDITOR_SCENE)


func _change_scene(path: String) -> void:
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Cannot open scene %s: %s" % [path, error_string(err)])
