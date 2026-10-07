extends Control

## Settings: music and sound effect volume, language and fullscreen. Every change is applied
## and saved at once through SaveManager.

## Locale codes in the same order as the language list items.
const LOCALES: PackedStringArray = ["en", "sr_Latn"]
const LANGUAGE_KEYS: PackedStringArray = ["LANG_EN", "LANG_SR"]

@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _music_check: CheckButton = %MusicCheck
@onready var _sfx_check: CheckButton = %SfxCheck
@onready var _language: OptionButton = %LanguageOption
@onready var _fullscreen: CheckButton = %FullscreenCheck
@onready var _crt: CheckButton = %CrtCheck
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	AudioManager.play_music(&"menu")
	var data := SaveManager.data
	_music_slider.value = data.music_volume
	_sfx_slider.value = data.sfx_volume
	_music_check.button_pressed = data.music_on
	_sfx_check.button_pressed = data.sfx_on
	_music_slider.editable = data.music_on
	_sfx_slider.editable = data.sfx_on
	for key in LANGUAGE_KEYS:
		_language.add_item(key)
	_language.selected = maxi(LOCALES.find(data.language), 0)
	_fullscreen.button_pressed = data.fullscreen
	_crt.button_pressed = data.crt
	# Browsers decide fullscreen themselves.
	_fullscreen.visible = not OS.has_feature("web")
	%FullscreenLabel.visible = _fullscreen.visible

	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_check.toggled.connect(_on_music_toggled)
	_sfx_check.toggled.connect(_on_sfx_toggled)
	_language.item_selected.connect(_on_language_selected)
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	_crt.toggled.connect(_on_crt_toggled)
	_back_button.pressed.connect(GameSession.go_to_main_menu)
	_music_check.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameSession.go_to_main_menu()


func _on_music_changed(value: float) -> void:
	SaveManager.data.music_volume = value
	_apply()


func _on_sfx_changed(value: float) -> void:
	SaveManager.data.sfx_volume = value
	_apply()


func _on_music_toggled(enabled: bool) -> void:
	SaveManager.data.music_on = enabled
	_music_slider.editable = enabled
	_apply()


func _on_sfx_toggled(enabled: bool) -> void:
	SaveManager.data.sfx_on = enabled
	_sfx_slider.editable = enabled
	_apply()


func _on_language_selected(index: int) -> void:
	SaveManager.data.language = LOCALES[index]
	_apply()


func _on_fullscreen_toggled(enabled: bool) -> void:
	SaveManager.data.fullscreen = enabled
	_apply()


func _on_crt_toggled(enabled: bool) -> void:
	SaveManager.data.crt = enabled
	_apply()


func _apply() -> void:
	SaveManager.apply_settings()
	SaveManager.save()
