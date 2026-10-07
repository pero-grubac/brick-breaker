extends Control

## Level editor hub: the player's own sets. Create, rename, describe, edit, play, delete,
## export (.zip) and import sets, and read the format help ("Info").

var _sets: Array[LevelSetData] = []
var _selected: LevelSetData = null

@onready var _set_list: VBoxContainer = %SetList
@onready var _details: Control = %Details
@onready var _empty_label: Label = %EmptyLabel
@onready var _name_edit: LineEdit = %SetNameEdit
@onready var _author_edit: LineEdit = %AuthorEdit
@onready var _description_edit: TextEdit = %DescriptionEdit
@onready var _info_label: Label = %InfoLabel
@onready var _status: Label = %Status
@onready var _delete_dialog: ConfirmationDialog = %DeleteSetDialog


func _ready() -> void:
	%NewSetButton.pressed.connect(_new_set)
	%EditButton.pressed.connect(_edit_levels)
	%PlayButton.pressed.connect(func() -> void: GameSession.play(_selected, 0))
	%SaveInfoButton.pressed.connect(_save_info)
	%DeleteButton.pressed.connect(_delete_dialog.popup_centered)
	%ExportButton.pressed.connect(_ask_export)
	%ImportButton.pressed.connect(%ImportDialog.popup_centered)
	%InfoButton.pressed.connect(%FormatHelp.open)
	%ExportDialog.file_selected.connect(_export_to)
	%ImportDialog.file_selected.connect(_import_from)
	%BackButton.pressed.connect(GameSession.go_to_main_menu)
	_delete_dialog.confirmed.connect(_delete_selected)
	_refresh()
	%NewSetButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not %FormatHelp.visible:
		GameSession.go_to_main_menu()


func _refresh(select_dir: String = "") -> void:
	for child in _set_list.get_children():
		child.queue_free()
	_sets = LevelLoader.find_sets(LevelLoader.USER_SETS_DIR)
	var to_select: LevelSetData = null
	for level_set in _sets:
		var button := Button.new()
		button.text = level_set.name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.theme_type_variation = &"ToolButton"
		button.pressed.connect(_select.bind(level_set))
		_set_list.add_child(button)
		if level_set.dir_path == select_dir or to_select == null:
			to_select = level_set
	_select(to_select)


func _select(level_set: LevelSetData) -> void:
	_selected = level_set
	_details.visible = level_set != null
	_empty_label.visible = level_set == null
	if level_set == null:
		return
	_name_edit.text = level_set.name
	_author_edit.text = level_set.author
	_description_edit.text = level_set.description
	_info_label.text = tr("SETS_LEVEL_COUNT") % level_set.level_count()


func _new_set() -> void:
	var level_set := LevelLoader.create_set(tr("HUB_NEW_SET_NAME"))
	var first := LevelData.create_empty(tr("EDITOR_NEW_LEVEL_NAME") % 1)
	var levels: Array[LevelData] = [first]
	GameSession.open_level_editor(level_set, levels)
	# A brand-new set has never been saved.
	GameSession.editor_dirty = true


func _edit_levels() -> void:
	var levels := LevelLoader.load_all_levels(_selected)
	if levels.is_empty():
		levels.append(LevelData.create_empty(tr("EDITOR_NEW_LEVEL_NAME") % 1))
	GameSession.open_level_editor(_selected, levels)


func _save_info() -> void:
	_selected.name = _name_edit.text.strip_edges()
	_selected.author = _author_edit.text.strip_edges()
	_selected.description = _description_edit.text.strip_edges()
	var errors := LevelLoader.save_set(_selected, LevelLoader.load_all_levels(_selected))
	if errors.is_empty():
		_status.text = tr("EDITOR_SAVED")
		_refresh(_selected.dir_path)
	else:
		_status.text = tr("EDITOR_SAVE_FAILED") + " " + errors[0]


func _delete_selected() -> void:
	if _selected == null:
		return
	LevelLoader.delete_set(_selected)
	_status.text = ""
	_refresh()


func _ask_export() -> void:
	var dialog: FileDialog = %ExportDialog
	dialog.current_file = _selected.dir_path.get_file() + ".zip"
	dialog.popup_centered()


func _export_to(path: String) -> void:
	if not path.get_extension().to_lower() == "zip":
		path += ".zip"
	var err := LevelLoader.export_set_zip(_selected, path)
	if err == OK:
		_status.text = tr("HUB_EXPORTED") % path
	else:
		_status.text = "%s %s" % [tr("HUB_EXPORT_FAILED"), error_string(err)]


func _import_from(path: String) -> void:
	var result := LevelLoader.import_path(path)
	if not result.is_ok():
		_refresh()
		_status.text = tr("HUB_IMPORT_FAILED") + "\n" + "\n".join(result.errors.slice(0, 4))
		return
	_refresh(result.level_set.dir_path)
	var message := tr("HUB_IMPORTED") % [result.level_set.name, result.level_set.level_count()]
	if not result.skipped.is_empty():
		message += "\n" + tr("HUB_IMPORT_SKIPPED") + "\n" + "\n".join(result.skipped.slice(0, 4))
	_status.text = message
