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
