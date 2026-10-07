class_name LevelSetData
extends RefCounted

## A level set manifest (set.json): metadata plus the ordered list of level files.

const FORMAT_VERSION: int = 1
const MANIFEST_FILE: String = "set.json"

var id: String = ""
var name: String = ""
var author: String = ""
var description: String = ""
## Level file names relative to `dir_path`, in play order.
var level_files: PackedStringArray = []
## Folder the set was loaded from (res://levels/<set> or user://levelsets/<set>).
var dir_path: String = ""


func level_count() -> int:
	return level_files.size()


func level_path(index: int) -> String:
	return dir_path.path_join(level_files[index])
