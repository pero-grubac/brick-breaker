extends Control

## Main menu: Play, Settings, Quit (and the level editor once it exists).

@onready var _play_button: Button = %PlayButton
@onready var _editor_button: Button = %EditorButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_play_button.pressed.connect(GameSession.go_to_set_select)
	_settings_button.pressed.connect(GameSession.go_to_settings)
	_quit_button.pressed.connect(get_tree().quit)
	# The level editor arrives in stage C; a browser tab cannot be quit.
	_editor_button.visible = false
	_quit_button.visible = not OS.has_feature("web")
	_play_button.grab_focus()
