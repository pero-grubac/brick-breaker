extends Node

## Builds ui/theme.tres (retro arcade theme). Bevelled 9-slice
## textures are generated pixel by pixel and saved as PNG next to the theme.
## Run it twice (with --import in between) so the theme references the imported PNGs:
##   godot --headless --path . -s res://tools/run_harness.gd -- res://tools/make_retro_theme.gd

const UI := "res://ui/"
const HEADING_FONT := "res://assets/fonts/press_start_2p.ttf"
const BODY_FONT := "res://assets/fonts/pixelify_sans.ttf"

const OUTLINE := Color(0.02, 0.02, 0.06)
const TEXT := Color(0.96, 0.96, 1.0)
const TEXT_DIM := Color(0.62, 0.66, 0.82)
const FOCUS := Color(1.0, 0.84, 0.2)

## 9-slice image size and bevel thickness in pixels.
const SIZE := 16
const BEVEL := 3
const MARGIN := 5


func _ready() -> void:
	var t := Theme.new()
	var heading: FontFile = load(HEADING_FONT)
	var body: FontFile = load(BODY_FONT)
	t.default_font = heading
	t.default_font_size = 16

	var btn := _bevel("button", Color(0.16, 0.2, 0.5), false)
	var btn_hover := _bevel("button_hover", Color(0.24, 0.3, 0.68), false)
	var btn_pressed := _bevel("button_pressed", Color(0.12, 0.14, 0.36), true)
	var btn_disabled := _bevel("button_disabled", Color(0.14, 0.15, 0.22), false)
	var focus := _frame("focus", FOCUS)
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, btn)
		t.set_stylebox("hover", type, btn_hover)
		t.set_stylebox("pressed", type, btn_pressed)
		t.set_stylebox("hover_pressed", type, btn_pressed)
		t.set_stylebox("disabled", type, btn_disabled)
		t.set_stylebox("focus", type, focus)
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, FOCUS)
		t.set_color("font_focus_color", type, FOCUS)
		t.set_color("font_pressed_color", type, TEXT_DIM)
		t.set_color("font_disabled_color", type, Color(0.4, 0.42, 0.5))
		t.set_color("font_outline_color", type, OUTLINE)
		t.set_constant("outline_size", type, 4)
	t.set_stylebox("focus", "CheckButton", focus)
	t.set_stylebox("focus", "HSlider", focus)

	var panel := _bevel("panel", Color(0.07, 0.08, 0.2), false, Color(0.25, 0.85, 0.95))
	for type in ["PanelContainer", "Panel"]:
		t.set_stylebox("panel", type, panel)

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", OUTLINE)
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)

	# "BodyLabel": readable pixel font for longer texts (descriptions, help).
	t.add_type("BodyLabel")
	t.set_type_variation("BodyLabel", "Label")
	t.set_font("font", "BodyLabel", body)
	t.set_font_size("font_size", "BodyLabel", 24)
	t.set_color("font_color", "BodyLabel", TEXT)
	t.set_constant("shadow_offset_x", "BodyLabel", 1)
	t.set_constant("shadow_offset_y", "BodyLabel", 1)

	t.set_constant("separation", "VBoxContainer", 12)
	t.set_constant("separation", "HBoxContainer", 12)

	var track := _flat(Color(0.05, 0.05, 0.14), 6)
	t.set_stylebox("slider", "HSlider", track)
	var fill := _flat(Color(0.25, 0.85, 0.95), 6)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var grabber := _square_icon("grabber", 18, FOCUS)
	t.set_icon("grabber", "HSlider", grabber)
	t.set_icon("grabber_highlight", "HSlider", grabber)

	print("theme: ", error_string(ResourceSaver.save(t, UI + "theme.tres")))
	get_tree().quit()


## Bevelled box: light top/left, dark bottom/right, black outline. `sunken` swaps the bevel.
func _bevel(file: String, base: Color, sunken: bool, rim: Color = Color.TRANSPARENT) -> StyleBoxTexture:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var light := base.lightened(0.45)
	var dark := base.darkened(0.55)
	if sunken:
		var tmp := light
		light = dark
		dark = tmp
	for y in SIZE:
		for x in SIZE:
			var c := base
			var edge := mini(mini(x, y), mini(SIZE - 1 - x, SIZE - 1 - y))
			if edge == 0:
				c = OUTLINE
			elif edge <= BEVEL:
				c = light if mini(x, y) < mini(SIZE - 1 - x, SIZE - 1 - y) else dark
				if rim.a > 0.0 and edge == 1:
					c = rim
			img.set_pixel(x, y, c)
	var tex := _save_png(img, file)
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.set_texture_margin_all(BEVEL + 1)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


## Hollow frame used for keyboard/gamepad focus.
func _frame(file: String, color: Color) -> StyleBoxTexture:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	for y in SIZE:
		for x in SIZE:
			var edge := mini(mini(x, y), mini(SIZE - 1 - x, SIZE - 1 - y))
			if edge < 3:
				img.set_pixel(x, y, color)
	var box := StyleBoxTexture.new()
	box.texture = _save_png(img, file)
	box.set_texture_margin_all(3)
	box.draw_center = false
	return box


func _flat(color: Color, height: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = OUTLINE
	box.set_border_width_all(2)
	box.content_margin_top = height / 2.0
	box.content_margin_bottom = height / 2.0
	return box


func _square_icon(file: String, size: int, color: Color) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(OUTLINE)
	img.fill_rect(Rect2i(2, 2, size - 4, size - 4), color)
	img.fill_rect(Rect2i(2, 2, size - 4, 3), color.lightened(0.5))
	return _save_png(img, file)


func _save_png(img: Image, file: String) -> Texture2D:
	var path := UI + file + ".png"
	img.save_png(ProjectSettings.globalize_path(path))
	# Second run (after --import): reference the imported PNG instead of embedding the image.
	if ResourceLoader.exists(path):
		return load(path)
	return ImageTexture.create_from_image(img)
