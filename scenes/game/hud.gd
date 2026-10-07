class_name Hud
extends CanvasLayer

## In-game HUD: lives and level name (driven by EventBus) and a center message set by Game.

@onready var _lives_label: Label = $LivesLabel
@onready var _message_label: Label = $MessageLabel
@onready var _level_label: Label = $LevelLabel


func _ready() -> void:
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.level_started.connect(_on_level_started)


func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.show()


func hide_message() -> void:
	_message_label.hide()


func _on_lives_changed(lives: int) -> void:
	_lives_label.text = "Lives: %d" % lives


func _on_level_started(level_number: int, level_count: int, level_name: String) -> void:
	_level_label.text = "Level %d/%d - %s" % [level_number, level_count, level_name]
