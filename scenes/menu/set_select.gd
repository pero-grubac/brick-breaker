extends Control

## Choose a level set (built-in first, then the player's own) and the level to start from.
## A level is a valid start if it is level 1 or the player has cleared it (SaveData rule).

const LEVEL_BUTTON_SIZE: Vector2 = Vector2(68, 52)
const SECTION_COLOR: Color = Color(0.6, 0.63, 0.7)

var _sets: Array[LevelSetData] = []
var _builtin_count: int = 0
var _selected: LevelSetData = null

@onready var _set_list: VBoxContainer = %SetList
@onready var _set_name: Label = %SetName
@onready var _set_info: Label = %SetInfo
@onready var _description: Label = %Description
@onready var _level_grid: GridContainer = %LevelGrid
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(GameSession.go_to_main_menu)
	var builtin := LevelLoader.find_sets(LevelLoader.BUILTIN_SETS_DIR)
	_builtin_count = builtin.size()
	_sets = builtin
	_sets.append_array(LevelLoader.find_sets(LevelLoader.USER_SETS_DIR))
	_build_set_list()
	if not _sets.is_empty():
		_select_set(_sets[0])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameSession.go_to_main_menu()


func _build_set_list() -> void:
	var first_button: Button = null
	for i in _sets.size():
		if i == 0:
			_add_section("SETS_BUILTIN")
		elif i == _builtin_count:
			_add_section("SETS_CUSTOM")
		var level_set := _sets[i]
		var button := Button.new()
		button.text = level_set.name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED  # set names are data
		button.pressed.connect(_select_set.bind(level_set))
		button.focus_entered.connect(_select_set.bind(level_set))
		_set_list.add_child(button)
		if first_button == null:
			first_button = button
	if first_button != null:
		first_button.grab_focus()


func _add_section(key: String) -> void:
	var label := Label.new()
	label.text = key
	label.add_theme_color_override("font_color", SECTION_COLOR)
	label.add_theme_font_size_override("font_size", 18)
	_set_list.add_child(label)


func _select_set(level_set: LevelSetData) -> void:
	if _selected == level_set:
		return
	_selected = level_set
	_set_name.text = level_set.name
	var info := tr("SETS_LEVEL_COUNT") % level_set.level_count()
	if not level_set.author.is_empty():
		info += "   " + tr("SETS_BY") % level_set.author
	var best := SaveManager.data.best_score(level_set.id)
	if best > 0:
		info += "   " + tr("SETS_BEST") % best
	_set_info.text = info
	_description.text = level_set.description
	_build_level_grid(level_set)


func _build_level_grid(level_set: LevelSetData) -> void:
	for child in _level_grid.get_children():
		child.queue_free()
	var starts := SaveManager.data.selectable_starts(level_set.id, level_set.level_count())
	for i in level_set.level_count():
		var button := Button.new()
		button.text = str(i + 1)
		button.custom_minimum_size = LEVEL_BUTTON_SIZE
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		if i in starts:
			var result := LevelLoader.load_level(level_set, i)
			button.tooltip_text = result.level.name if result.is_ok() else ""
			button.pressed.connect(GameSession.play.bind(level_set, i))
		else:
			button.disabled = true
			button.tooltip_text = tr("LEVEL_LOCKED")
		_level_grid.add_child(button)
