class_name LevelData
extends RefCounted

## One parsed and validated level. Built by LevelParser, read by Game (and later the editor).

const FORMAT_VERSION: int = 1
const COLUMNS: int = 18
const MAX_ROWS: int = 20

var name: String = ""
var author: String = ""
## Brick type id per cell, row by row; "" means an empty cell.
var cells: Array[PackedStringArray] = []

# Settings, with defaults for anything the level file leaves out.
var ball_speed: float = 1.0
var drop_modifier: float = 1.0
## Either "all" or a list of power-up ids.
var allowed_powerups: Variant = "all"
var banned_powerups: PackedStringArray = []
var background: String = ""
var music: String = ""


func row_count() -> int:
	return cells.size()


## Brick type id at a cell, or "" if empty.
func cell(row: int, column: int) -> String:
	return cells[row][column]


func set_cell(row: int, column: int, brick_id: String) -> void:
	cells[row][column] = brick_id


## A new level with MAX_ROWS empty rows, ready for the editor.
static func create_empty(level_name: String) -> LevelData:
	var level := LevelData.new()
	level.name = level_name
	for r in MAX_ROWS:
		level.cells.append(empty_row())
	return level


static func empty_row() -> PackedStringArray:
	var row := PackedStringArray()
	row.resize(COLUMNS)
	row.fill("")
	return row


## Pads the grid to MAX_ROWS rows (the editor always edits the full grid).
func pad_to_full_grid() -> void:
	while cells.size() < MAX_ROWS:
		cells.append(empty_row())


## Number of rows up to the last row that has a brick (trailing empty rows are not saved).
func used_row_count() -> int:
	for r in range(cells.size() - 1, -1, -1):
		for id in cells[r]:
			if not id.is_empty():
				return r + 1
	return 0


## Independent copy (the editor edits copies, so "Test" and undo never touch the original).
func duplicate_level() -> LevelData:
	var copy := LevelData.new()
	copy.name = name
	copy.author = author
	for row in cells:
		copy.cells.append(row.duplicate())
	copy.ball_speed = ball_speed
	copy.drop_modifier = drop_modifier
	copy.allowed_powerups = allowed_powerups.duplicate() if allowed_powerups is PackedStringArray \
			else allowed_powerups
	copy.banned_powerups = banned_powerups.duplicate()
	copy.background = background
	copy.music = music
	return copy
