extends Control

## Level editor: paint bricks on the grid, edit the level's settings, move between the levels
## of the set, test-play a level and save the set. Works on GameSession's editor state, so the
## edits survive a "Test" trip to the game scene.

## Palette order (brick type ids); types missing here are added at the end.
const PALETTE_ORDER: PackedStringArray = [
	"normal_red", "normal_orange", "normal_yellow", "normal_green", "normal", "normal_purple",
	"hard2", "hard3", "steel", "tnt", "bonus",
]
const MAX_UNDO: int = 100

var _set: LevelSetData = null
var _levels: Array[LevelData] = []
var _index: int = 0
var _undo: Array[Array] = []
var _redo: Array[Array] = []
var _power_ups: Dictionary[String, PowerUpDef] = {}
## True while the UI is being filled from the level (so it does not count as an edit).
var _syncing: bool = false

@onready var _grid: EditorGrid = %Grid
@onready var _palette: HBoxContainer = %Palette
@onready var _brick_name: Label = %BrickName
@onready var _pencil: Button = %PencilButton
@onready var _eraser: Button = %EraserButton
@onready var _rect: Button = %RectButton
@onready var _row_copy: Button = %RowCopyButton
@onready var _mirror: Button = %MirrorButton
@onready var _undo_button: Button = %UndoButton
@onready var _redo_button: Button = %RedoButton
@onready var _cell_label: Label = %CellLabel
@onready var _name_edit: LineEdit = %NameEdit
@onready var _speed_spin: SpinBox = %SpeedSpin
@onready var _drop_spin: SpinBox = %DropSpin
@onready var _power_ups_button: MenuButton = %PowerUpsButton
@onready var _level_label: Label = %LevelLabel
@onready var _status: Label = %Status
@onready var _leave_dialog: ConfirmationDialog = %LeaveDialog
@onready var _delete_dialog: ConfirmationDialog = %DeleteDialog


func _ready() -> void:
	if GameSession.editor_set == null:
		# Opened directly (F6): start a scratch set in memory.
		var scratch := LevelLoader.create_set(tr("HUB_NEW_SET_NAME"))
		var levels: Array[LevelData] = [LevelData.create_empty(tr("EDITOR_NEW_LEVEL_NAME") % 1)]
		GameSession.editor_set = scratch
		GameSession.editor_levels = levels
	_set = GameSession.editor_set
	_levels = GameSession.editor_levels
	_index = clampi(GameSession.editor_index, 0, _levels.size() - 1)
	for level in _levels:
		level.pad_to_full_grid()
	_power_ups = PowerUpCatalog.load_all()

	_build_palette()
	_build_power_up_menu()
	_connect_ui()
	_show_level()
	_set_status(tr("EDITOR_UNSAVED") if GameSession.editor_dirty else tr("EDITOR_HELP"))


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.ctrl_pressed and key.keycode == KEY_Z and key.shift_pressed:
		_redo_step()
	elif key.ctrl_pressed and key.keycode == KEY_Z:
		_undo_step()
	elif key.ctrl_pressed and key.keycode == KEY_Y:
		_redo_step()
	elif key.ctrl_pressed and key.keycode == KEY_S:
		_save()
	elif key.keycode == KEY_ESCAPE:
		_on_back()
	else:
		return
	get_viewport().set_input_as_handled()


# --- building the UI ---

func _build_palette() -> void:
	var group := ButtonGroup.new()
	var ids := Array(PALETTE_ORDER)
	for id: String in LevelLoader.brick_types.keys():
		if not id in ids:
			ids.append(id)
	var first: BrickSwatch = null
	for id: String in ids:
		var type := LevelLoader.get_brick_type(id)
		if type == null:
			continue
		var swatch := BrickSwatch.new()
		swatch.setup(type)
		swatch.button_group = group
		swatch.toggled.connect(func(on: bool) -> void:
			if on:
				_select_brick(id))
		_palette.add_child(swatch)
		if first == null:
			first = swatch
	first.button_pressed = true


func _build_power_up_menu() -> void:
	var popup := _power_ups_button.get_popup()
	popup.hide_on_checkable_item_selection = false
	var i := 0
	for id in _power_ups:
		popup.add_check_item(_power_ups[id].display_name, i)
		popup.set_item_metadata(i, id)
		i += 1
	popup.id_pressed.connect(_on_power_up_toggled)


func _connect_ui() -> void:
	var tools := ButtonGroup.new()
	for pair in [[_pencil, EditorGrid.Tool.PENCIL], [_eraser, EditorGrid.Tool.ERASER],
			[_rect, EditorGrid.Tool.RECT], [_row_copy, EditorGrid.Tool.ROW_COPY]]:
		var button: Button = pair[0]
		var grid_tool: EditorGrid.Tool = pair[1]
		button.toggle_mode = true
		button.button_group = tools
		button.toggled.connect(func(on: bool) -> void:
			if on:
				_grid.tool = grid_tool)
	_pencil.button_pressed = true
	_mirror.toggle_mode = true
	_mirror.toggled.connect(func(on: bool) -> void:
		_grid.mirror = on
		_grid.queue_redraw())
	_undo_button.pressed.connect(_undo_step)
	_redo_button.pressed.connect(_redo_step)

	_grid.about_to_change.connect(_push_undo)
	_grid.changed.connect(_mark_dirty)
	_grid.hovered_cell_changed.connect(_on_hovered_cell)

	_name_edit.text_changed.connect(func(text: String) -> void:
		if not _syncing:
			_current().name = text
			_update_level_label()
			_mark_dirty())
	_speed_spin.value_changed.connect(func(value: float) -> void:
		if not _syncing:
			_current().ball_speed = value
			_mark_dirty())
	_drop_spin.value_changed.connect(func(value: float) -> void:
		if not _syncing:
			_current().drop_modifier = value
			_mark_dirty())

	%PrevButton.pressed.connect(func() -> void: _go_to(_index - 1))
	%NextButton.pressed.connect(func() -> void: _go_to(_index + 1))
	%AddButton.pressed.connect(_add_level)
	%DuplicateButton.pressed.connect(_duplicate_level)
	%DeleteButton.pressed.connect(_delete_dialog.popup_centered)
	%MoveLeftButton.pressed.connect(func() -> void: _move_level(-1))
	%MoveRightButton.pressed.connect(func() -> void: _move_level(1))
	%TestButton.pressed.connect(_test)
	%SaveButton.pressed.connect(_save)
	%BackButton.pressed.connect(_on_back)
	_leave_dialog.confirmed.connect(GameSession.go_to_editor_hub)
	_delete_dialog.confirmed.connect(_delete_level)


# --- levels ---

func _current() -> LevelData:
	return _levels[_index]


func _show_level() -> void:
	_syncing = true
	var level := _current()
	_grid.level = level
	_name_edit.text = level.name
	_speed_spin.value = level.ball_speed
	_drop_spin.value = level.drop_modifier
	var popup := _power_ups_button.get_popup()
	for i in popup.item_count:
		popup.set_item_checked(i, not popup.get_item_metadata(i) in level.banned_powerups)
	_syncing = false
	_undo.clear()
	_redo.clear()
	_update_undo_buttons()
	_update_level_label()
	GameSession.editor_index = _index


func _update_level_label() -> void:
	_level_label.text = tr("EDITOR_LEVEL_N") % [_index + 1, _levels.size()]
	%PrevButton.disabled = _index == 0
	%NextButton.disabled = _index == _levels.size() - 1
	%MoveLeftButton.disabled = _index == 0
	%MoveRightButton.disabled = _index == _levels.size() - 1
	%DeleteButton.disabled = _levels.size() == 1


func _go_to(index: int) -> void:
	if index < 0 or index >= _levels.size():
		return
	_index = index
	_show_level()


func _add_level() -> void:
	var level := LevelData.create_empty(tr("EDITOR_NEW_LEVEL_NAME") % (_levels.size() + 1))
	level.author = _set.author
	_levels.insert(_index + 1, level)
	_mark_dirty()
	_go_to(_index + 1)


func _duplicate_level() -> void:
	var copy := _current().duplicate_level()
	copy.name += " (2)"
	_levels.insert(_index + 1, copy)
	_mark_dirty()
	_go_to(_index + 1)


func _delete_level() -> void:
	if _levels.size() <= 1:
		return
	_levels.remove_at(_index)
	_index = mini(_index, _levels.size() - 1)
	_mark_dirty()
	_show_level()


func _move_level(direction: int) -> void:
	var target := _index + direction
	if target < 0 or target >= _levels.size():
		return
	var level := _levels[_index]
	_levels.remove_at(_index)
	_levels.insert(target, level)
	_index = target
	_mark_dirty()
	_update_level_label()
	GameSession.editor_index = _index


# --- editing ---

func _select_brick(id: String) -> void:
	_grid.brick_id = id
	_brick_name.text = "BRICK_" + id.to_upper()
	if _grid.tool == EditorGrid.Tool.ERASER:
		_pencil.button_pressed = true


func _on_power_up_toggled(item_id: int) -> void:
	var popup := _power_ups_button.get_popup()
	var index := popup.get_item_index(item_id)
	var allowed := not popup.is_item_checked(index)
	popup.set_item_checked(index, allowed)
	var power_up_id: String = popup.get_item_metadata(index)
	var banned := _current().banned_powerups
	if allowed and power_up_id in banned:
		banned.remove_at(banned.find(power_up_id))
	elif not allowed and not power_up_id in banned:
		banned.append(power_up_id)
	_mark_dirty()


func _on_hovered_cell(cell: Vector2i) -> void:
	_cell_label.text = "" if cell == EditorGrid.NO_CELL \
			else tr("EDITOR_CELL") % [cell.y + 1, cell.x + 1]


func _push_undo() -> void:
	_undo.append(_snapshot())
	if _undo.size() > MAX_UNDO:
		_undo.pop_front()
	_redo.clear()
	_update_undo_buttons()


func _undo_step() -> void:
	if _undo.is_empty():
		return
	_redo.append(_snapshot())
	_restore(_undo.pop_back())


func _redo_step() -> void:
	if _redo.is_empty():
		return
	_undo.append(_snapshot())
	_restore(_redo.pop_back())


func _snapshot() -> Array:
	var copy: Array = []
	for row in _current().cells:
		copy.append(row.duplicate())
	return copy


func _restore(snapshot: Array) -> void:
	var cells: Array[PackedStringArray] = []
	for row: PackedStringArray in snapshot:
		cells.append(row)
	_current().cells = cells
	_grid.queue_redraw()
	_update_undo_buttons()
	_mark_dirty()


func _update_undo_buttons() -> void:
	_undo_button.disabled = _undo.is_empty()
	_redo_button.disabled = _redo.is_empty()


func _mark_dirty() -> void:
	GameSession.editor_dirty = true
	_set_status(tr("EDITOR_UNSAVED"))


func _set_status(text: String) -> void:
	_status.text = text


# --- test, save, leave ---

func _test() -> void:
	GameSession.test_from_editor(_current())


func _save() -> void:
	var errors := LevelLoader.save_set(_set, _levels)
	if errors.is_empty():
		GameSession.editor_dirty = false
		_set_status(tr("EDITOR_SAVED"))
	else:
		_set_status(tr("EDITOR_SAVE_FAILED") + " " + errors[0])


func _on_back() -> void:
	if GameSession.editor_dirty:
		_leave_dialog.popup_centered()
	else:
		GameSession.go_to_editor_hub()
