extends GutTest

## Touch input: what counts as a tap (launch), and that every touch hint has a translation.


func test_short_still_touch_is_a_tap() -> void:
	assert_true(TouchControls.is_tap(Vector2(600, 400), Vector2(605, 402), 120))


func test_dragging_is_not_a_tap() -> void:
	assert_false(TouchControls.is_tap(Vector2(600, 400), Vector2(700, 400), 120))


func test_long_press_is_not_a_tap() -> void:
	assert_false(TouchControls.is_tap(Vector2(600, 400), Vector2(600, 400),
			TouchControls.TAP_MAX_MSEC + 1))


func test_tap_on_the_top_bar_is_ignored() -> void:
	# The pause button lives there.
	assert_false(TouchControls.is_tap(Vector2(1220, 40), Vector2(1220, 40), 100))


func test_every_touch_hint_has_a_translation() -> void:
	var game_script: GDScript = load("res://scenes/game/game.gd")
	var keys: Array = game_script.get_script_constant_map()["TOUCH_HINTS"]
	for locale in ["en", "sr_Latn"]:
		TranslationServer.set_locale(locale)
		for key: String in keys:
			var touch_key := key + "_TOUCH"
			assert_ne(tr(touch_key), touch_key, locale + " " + touch_key)
	TranslationServer.set_locale("en")
