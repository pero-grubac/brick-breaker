extends GutTest

## Unit tests for SaveData: unlock rule, best score, round trip and damaged saves.

const SET := "builtin.classic"

var _s: SaveData


func before_each() -> void:
	_s = SaveData.new()


func test_fresh_save_allows_only_level_1() -> void:
	assert_eq(_s.selectable_starts(SET, 30), [0] as Array[int])


func test_cleared_levels_become_starts() -> void:
	_s.mark_cleared(SET, 0)
	_s.mark_cleared(SET, 1)
	assert_eq(_s.selectable_starts(SET, 30), [0, 1] as Array[int])
	assert_false(_s.is_selectable_start(SET, 2, 30), "reached but not cleared")


func test_cleared_out_of_order() -> void:
	_s.mark_cleared(SET, 5)
	_s.mark_cleared(SET, 2)
	assert_eq(_s.selectable_starts(SET, 30), [0, 2, 5] as Array[int])


func test_starts_ignore_levels_beyond_the_set() -> void:
	_s.mark_cleared(SET, 12)
	assert_eq(_s.selectable_starts(SET, 10), [0] as Array[int], "set got shorter")


func test_marking_twice_is_harmless() -> void:
	_s.mark_cleared(SET, 3)
	_s.mark_cleared(SET, 3)
	assert_eq(_s.selectable_starts(SET, 30), [0, 3] as Array[int])


func test_sets_are_independent() -> void:
	_s.mark_cleared(SET, 4)
	assert_false(_s.is_level_cleared("other.set", 4))


func test_best_score() -> void:
	assert_true(_s.submit_score(SET, 1000))
	assert_false(_s.submit_score(SET, 500))
	assert_true(_s.submit_score(SET, 1500))
	assert_eq(_s.best_score(SET), 1500)


func test_round_trip_through_json() -> void:
	_s.music_volume = 0.3
	_s.sfx_volume = 0.6
	_s.language = "sr_Latn"
	_s.fullscreen = true
	_s.crt = false
	_s.music_on = false
	_s.mark_cleared(SET, 0)
	_s.mark_cleared(SET, 7)
	_s.submit_score(SET, 4200)
	var loaded := SaveData.from_dict(JSON.parse_string(JSON.stringify(_s.to_dict())))
	assert_almost_eq(loaded.music_volume, 0.3, 0.0001)
	assert_almost_eq(loaded.sfx_volume, 0.6, 0.0001)
	assert_eq(loaded.language, "sr_Latn")
	assert_true(loaded.fullscreen)
	assert_false(loaded.crt)
	assert_false(loaded.music_on)
	assert_true(loaded.sfx_on)
	assert_eq(loaded.selectable_starts(SET, 30), [0, 7] as Array[int])
	assert_eq(loaded.best_score(SET), 4200)


func test_damaged_save_falls_back_to_defaults() -> void:
	for bad: Variant in [null, "text", [1, 2], {"settings": "x", "progress": 5}]:
		var loaded := SaveData.from_dict(bad)
		assert_eq(loaded.music_volume, SaveData.DEFAULT_VOLUME)
		assert_eq(loaded.selectable_starts(SET, 30), [0] as Array[int])


func test_bad_values_inside_a_save_are_skipped() -> void:
	var data := {
		"settings": {"music_volume": 7, "sfx_volume": "loud", "fullscreen": "yes"},
		"progress": {SET: {"cleared": [1, "two", -3, 4.0], "best_score": "lots"}},
	}
	var loaded := SaveData.from_dict(data)
	assert_eq(loaded.music_volume, 1.0, "clamped")
	assert_eq(loaded.sfx_volume, SaveData.DEFAULT_VOLUME)
	assert_false(loaded.fullscreen)
	assert_eq(loaded.selectable_starts(SET, 30), [0, 1, 4] as Array[int])
	assert_eq(loaded.best_score(SET), 0)
