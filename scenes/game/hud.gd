class_name Hud
extends CanvasLayer

## In-game HUD: lives, score, combo, level name and active power-ups (driven by EventBus), a
## center message set by Game, the pause menu and a pause button for touch screens.

signal pause_requested
signal resume_requested
signal restart_requested
signal main_menu_requested

@onready var _lives_label: Label = $LivesLabel
@onready var _message_label: Label = $MessageLabel
@onready var _level_label: Label = $LevelLabel
@onready var _score_label: Label = $ScoreLabel
@onready var _active_label: Label = $ActiveLabel
@onready var _pause_menu: Control = $PauseMenu
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MainMenuButton
@onready var _pause_button: Button = %PauseButton

var _score: int = 0
var _combo: float = 1.0


func _ready() -> void:
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.level_started.connect(_on_level_started)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.active_powerups_changed.connect(_on_active_powerups_changed)
	EventBus.paused_changed.connect(_on_paused_changed)
	_resume_button.pressed.connect(resume_requested.emit)
	_restart_button.pressed.connect(restart_requested.emit)
	_menu_button.pressed.connect(main_menu_requested.emit)
	_pause_button.pressed.connect(pause_requested.emit)
	_pause_menu.hide()


func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.show()


func hide_message() -> void:
	_message_label.hide()


func _on_lives_changed(lives: int) -> void:
	_lives_label.text = tr("HUD_LIVES") % lives


func _on_level_started(level_number: int, level_count: int, level_name: String) -> void:
	_level_label.text = tr("HUD_LEVEL") % [level_number, level_count, level_name]


func _on_score_changed(score: int) -> void:
	_score = score
	_update_score_label()


func _on_combo_changed(combo: float) -> void:
	_combo = combo
	_update_score_label()


func _update_score_label() -> void:
	var text := tr("HUD_SCORE") % TextFormat.group_thousands(_score)
	if _combo > 1.0:
		text += "   x%s" % String.num(_combo, 1)
	_score_label.text = text


func _on_active_powerups_changed(lines: PackedStringArray) -> void:
	_active_label.text = "   ".join(lines)


func _on_paused_changed(paused: bool) -> void:
	# The pause menu replaces the normal message while paused.
	_pause_menu.visible = paused
	_pause_button.visible = not paused
	_message_label.self_modulate.a = 0.0 if paused else 1.0
	if paused:
		_resume_button.grab_focus()
