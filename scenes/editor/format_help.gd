class_name FormatHelp
extends Control

## "Info" overlay: explains the level set / level JSON format, in English or Serbian (latin).
## The example level is built by LevelSerializer, so it is always valid; the brick and power-up
## lists come from the game's own catalogs.

const HELP_PATH: String = "res://i18n/help/level_format.%s.txt"
const LOCALES: PackedStringArray = ["en", "sr_Latn"]

var _locale: String = "en"

@onready var _text: RichTextLabel = %HelpText
@onready var _status: Label = %HelpStatus


func _ready() -> void:
	hide()
	%EnglishButton.pressed.connect(_show_locale.bind("en"))
	%SerbianButton.pressed.connect(_show_locale.bind("sr_Latn"))
	%CopyButton.pressed.connect(_copy_example)
	%CloseButton.pressed.connect(hide)


func open() -> void:
	var current := TranslationServer.get_locale()
	_show_locale("sr_Latn" if current.begins_with("sr") else "en")
	show()
	%CloseButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


func _show_locale(locale: String) -> void:
	_locale = locale
	%EnglishButton.button_pressed = locale == "en"
	%SerbianButton.button_pressed = locale != "en"
	var text := FileAccess.get_file_as_string(HELP_PATH % locale)
	text = text.replace("{LEVEL_EXAMPLE}", example_json().strip_edges())
	text = text.replace("{BRICKS}", _brick_list())
	text = text.replace("{POWERUPS}", _power_up_list())
	_text.text = text
	_text.scroll_to_line(0)
	_status.text = ""


## A small valid level used as the example (and copied to the clipboard).
static func example_json() -> String:
	var level := LevelData.create_empty("My Level")
	level.author = "Pero"
	for c in LevelData.COLUMNS:
		level.set_cell(0, c, "normal_red")
		level.set_cell(4, c, "steel" if c < 6 or c > 11 else "")
	for c in range(3, 15):
		level.set_cell(2, c, "hard2")
	level.set_cell(2, 8, "tnt")
	level.set_cell(2, 9, "tnt")
	return LevelSerializer.level_to_json(level)


func _translate(key: String) -> String:
	var translation := TranslationServer.get_translation_object(_locale)
	if translation == null:
		return key
	var message := String(translation.get_message(key))
	return message if not message.is_empty() else key


func _brick_list() -> String:
	var lines := PackedStringArray()
	var ids := LevelLoader.brick_types.keys()
	ids.sort()
	for id: String in ids:
		lines.append("[b]%s[/b]: %s" % [id, _translate("BRICK_" + id.to_upper())])
	return "\n".join(lines)


func _power_up_list() -> String:
	var lines := PackedStringArray()
	var defs := PowerUpCatalog.load_all()
	for id in defs:
		lines.append("[b]%s[/b]: %s" % [id, _translate(defs[id].display_name)])
	return "\n".join(lines)


func _copy_example() -> void:
	DisplayServer.clipboard_set(example_json())
	_status.text = _translate("INFO_COPIED")
