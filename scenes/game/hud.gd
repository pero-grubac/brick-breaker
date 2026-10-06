class_name Hud
extends CanvasLayer

## In-game HUD: lives counter (driven by EventBus) and a center message set by Game.

@onready var _lives_label: Label = $LivesLabel
@onready var _message_label: Label = $MessageLabel


func _ready() -> void:
	EventBus.lives_changed.connect(_on_lives_changed)


func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.show()


func hide_message() -> void:
	_message_label.hide()


func _on_lives_changed(lives: int) -> void:
	_lives_label.text = "Lives: %d" % lives
