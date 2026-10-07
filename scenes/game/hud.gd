class_name Hud
extends CanvasLayer

## In-game HUD: lives, score, combo and level name (driven by EventBus) and a center message
## set by Game.

@onready var _lives_label: Label = $LivesLabel
@onready var _message_label: Label = $MessageLabel
@onready var _level_label: Label = $LevelLabel
@onready var _score_label: Label = $ScoreLabel
@onready var _active_label: Label = $ActiveLabel
@onready var _pause_label: Label = $PauseLabel

var _score: int = 0
var _combo: float = 1.0


func _ready() -> void:
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.level_started.connect(_on_level_started)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.active_powerups_changed.connect(_on_active_powerups_changed)
	EventBus.paused_changed.connect(_on_paused_changed)


func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.show()


func hide_message() -> void:
	_message_label.hide()


func _on_lives_changed(lives: int) -> void:
	_lives_label.text = "Lives: %d" % lives


func _on_level_started(level_number: int, level_count: int, level_name: String) -> void:
	_level_label.text = "Level %d/%d - %s" % [level_number, level_count, level_name]


func _on_score_changed(score: int) -> void:
	_score = score
	_update_score_label()


func _on_combo_changed(combo: float) -> void:
	_combo = combo
	_update_score_label()


func _update_score_label() -> void:
	var text := "Score %s" % _group_thousands(_score)
	if _combo > 1.0:
		text += "   x%s" % String.num(_combo, 1)
	_score_label.text = text


## 1234567 -> "1,234,567"
static func _group_thousands(value: int) -> String:
	var digits := str(absi(value))
	var groups: PackedStringArray = []
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.insert(0, digits)
	return ("-" if value < 0 else "") + ",".join(groups)


func _on_active_powerups_changed(lines: PackedStringArray) -> void:
	_active_label.text = "   ".join(lines)


func _on_paused_changed(paused: bool) -> void:
	# The pause text replaces the normal message while paused.
	_pause_label.visible = paused
	_message_label.self_modulate.a = 0.0 if paused else 1.0
