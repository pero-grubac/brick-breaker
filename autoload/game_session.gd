extends Node

## What the player chose in the menus (which set, which start level) and the scene changes
## between menus and the game. Registered as the `GameSession` autoload; it lives across scene
## changes, so the game scene can read the choice made in the menu.

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const SET_SELECT_SCENE: String = "res://scenes/menu/set_select.tscn"
const SETTINGS_SCENE: String = "res://scenes/menu/settings_menu.tscn"
const GAME_SCENE: String = "res://scenes/game/game.tscn"

## Set and start level for the next game. Null = the game scene was started directly (F6 in
## the editor), so it uses its own exported values.
var level_set: LevelSetData = null
var start_level: int = 0


func play(chosen_set: LevelSetData, chosen_start: int) -> void:
	level_set = chosen_set
	start_level = chosen_start
	_change_scene(GAME_SCENE)


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)


func go_to_set_select() -> void:
	_change_scene(SET_SELECT_SCENE)


func go_to_settings() -> void:
	_change_scene(SETTINGS_SCENE)


func _change_scene(path: String) -> void:
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Cannot open scene %s: %s" % [path, error_string(err)])
