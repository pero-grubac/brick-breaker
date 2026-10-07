class_name EditorGrid
extends Control

## The editable 18 x 20 brick grid, drawn at the same size and place as in the game.
## Left mouse button uses the current tool, right button always erases.
## Emits `about_to_change` before every edit (for undo) and `changed` after it.

signal about_to_change
signal changed
signal hovered_cell_changed(cell: Vector2i)

enum Tool { PENCIL, ERASER, RECT, ROW_COPY }

const COLUMNS: int = LevelData.COLUMNS
const ROWS: int = LevelData.MAX_ROWS
const BRICK_HEIGHT: float = 20.0
const GAP: float = 4.0
const EMPTY_CELL_COLOR: Color = Color(1, 1, 1, 0.05)
const HOVER_COLOR: Color = Color(1.0, 0.84, 0.2, 0.9)
const MIRROR_LINE_COLOR: Color = Color(0.25, 0.85, 0.95, 0.35)
const OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.06)
const BEVEL: float = 3.0
const TNT_LABEL_COLOR: Color = Color(1.0, 0.85, 0.2)
const TNT_FONT_SIZE: int = 16
const NO_CELL: Vector2i = Vector2i(-1, -1)

var level: LevelData = null:
	set(value):
		level = value
		queue_redraw()
var tool: Tool = Tool.PENCIL
var brick_id: String = "normal"
## Also paint the mirrored column (left-right symmetry).
var mirror: bool = false

var _brick_width: float = 0.0
var _hover: Vector2i = NO_CELL
## Mouse button held in the current stroke (MOUSE_BUTTON_NONE when idle).
var _stroke_button: MouseButton = MOUSE_BUTTON_NONE
var _rect_start: Vector2i = NO_CELL


func _ready() -> void:
	_brick_width = (size.x - GAP * (COLUMNS + 1)) / COLUMNS
	mouse_exited.connect(func() -> void: _set_hover(NO_CELL))
	resized.connect(func() -> void:
		_brick_width = (size.x - GAP * (COLUMNS + 1)) / COLUMNS
		queue_redraw())


func cell_rect(row: int, column: int) -> Rect2:
	return Rect2(GAP + column * (_brick_width + GAP), row * (BRICK_HEIGHT + GAP),
			_brick_width, BRICK_HEIGHT)


func cell_at(local: Vector2) -> Vector2i:
	var column := int((local.x - GAP / 2.0) / (_brick_width + GAP))
	var row := int((local.y + GAP / 2.0) / (BRICK_HEIGHT + GAP))
	if local.x < 0 or local.y < 0 or column < 0 or column >= COLUMNS or row < 0 or row >= ROWS:
		return NO_CELL
	return Vector2i(column, row)


func _gui_input(event: InputEvent) -> void:
	if level == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
			return
		var cell := cell_at(mb.position)
		if mb.pressed and _stroke_button == MOUSE_BUTTON_NONE and cell != NO_CELL:
			_begin_stroke(mb.button_index, cell)
		elif not mb.pressed and mb.button_index == _stroke_button:
			_end_stroke(cell)
		accept_event()
	elif event is InputEventMouseMotion:
		var cell := cell_at((event as InputEventMouseMotion).position)
		_set_hover(cell)
		if _stroke_button != MOUSE_BUTTON_NONE and cell != NO_CELL and _paints_while_dragging():
			_paint(cell)


func _begin_stroke(button: MouseButton, cell: Vector2i) -> void:
	_stroke_button = button
	about_to_change.emit()
	if _current_tool() == Tool.RECT:
		_rect_start = cell
		queue_redraw()
	elif _current_tool() == Tool.ROW_COPY:
		_copy_row(cell.y)
	else:
		_paint(cell)


func _end_stroke(cell: Vector2i) -> void:
	if _current_tool() == Tool.RECT and _rect_start != NO_CELL:
		var end := cell if cell != NO_CELL else _hover
		if end != NO_CELL:
			_fill_rect(_rect_start, end)
	_rect_start = NO_CELL
	_stroke_button = MOUSE_BUTTON_NONE
	changed.emit()
	queue_redraw()


## Right button always erases; RECT with the right button erases a rectangle.
func _current_tool() -> Tool:
	if _stroke_button == MOUSE_BUTTON_RIGHT and tool != Tool.RECT:
		return Tool.ERASER
	return tool


func _paints_while_dragging() -> bool:
	return _current_tool() == Tool.PENCIL or _current_tool() == Tool.ERASER


func _value_to_paint() -> String:
	var erase := _stroke_button == MOUSE_BUTTON_RIGHT or _current_tool() == Tool.ERASER
	return "" if erase else brick_id


func _paint(cell: Vector2i) -> void:
	var value := _value_to_paint()
	level.set_cell(cell.y, cell.x, value)
	if mirror:
		level.set_cell(cell.y, COLUMNS - 1 - cell.x, value)
	queue_redraw()


func _fill_rect(a: Vector2i, b: Vector2i) -> void:
	var value := _value_to_paint()
	for row in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
		for column in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
			level.set_cell(row, column, value)
			if mirror:
				level.set_cell(row, COLUMNS - 1 - column, value)


## Inserts a copy of `row` below it; the last row falls off the grid.
func _copy_row(row: int) -> void:
	if row >= ROWS - 1:
		return
	level.cells.insert(row + 1, level.cells[row].duplicate())
	level.cells.resize(ROWS)
	queue_redraw()


func _set_hover(cell: Vector2i) -> void:
	if cell != _hover:
		_hover = cell
		hovered_cell_changed.emit(cell)
		queue_redraw()


func _draw() -> void:
	if level == null:
		return
	for row in ROWS:
		for column in COLUMNS:
			var rect := cell_rect(row, column)
			var id := level.cell(row, column)
			if id.is_empty():
				draw_rect(rect, EMPTY_CELL_COLOR)
			else:
				_draw_brick(rect, id)
	if mirror:
		var x := size.x / 2.0
		draw_line(Vector2(x, 0), Vector2(x, size.y), MIRROR_LINE_COLOR, 2.0)
	if _rect_start != NO_CELL and _hover != NO_CELL:
		var a := cell_rect(mini(_rect_start.y, _hover.y), mini(_rect_start.x, _hover.x))
		var b := cell_rect(maxi(_rect_start.y, _hover.y), maxi(_rect_start.x, _hover.x))
		draw_rect(a.merge(b).grow(2.0), HOVER_COLOR, false, 2.0)
	elif _hover != NO_CELL:
		draw_rect(cell_rect(_hover.y, _hover.x).grow(2.0), HOVER_COLOR, false, 2.0)
		if mirror:
			draw_rect(cell_rect(_hover.y, COLUMNS - 1 - _hover.x).grow(2.0), HOVER_COLOR, false, 1.0)


func _draw_brick(rect: Rect2, id: String) -> void:
	var brick_type := LevelLoader.get_brick_type(id)
	var color := brick_type.color if brick_type != null else Color.MAGENTA
	RetroDraw.bevel_rect(self, rect, color, BEVEL, 0.45, 0.45, OUTLINE_COLOR)
	if id == "tnt":
		var font := RetroDraw.font()
		var text_size := font.get_string_size("TNT", HORIZONTAL_ALIGNMENT_LEFT, -1, TNT_FONT_SIZE)
		var baseline := rect.get_center() + Vector2(-text_size.x / 2.0,
				font.get_ascent(TNT_FONT_SIZE) - text_size.y / 2.0)
		draw_string(font, baseline, "TNT", HORIZONTAL_ALIGNMENT_LEFT, -1, TNT_FONT_SIZE,
				TNT_LABEL_COLOR)
