class_name PowerUpCatalog
extends RefCounted

## Loads every PowerUpDef from res://data/powerups (used by the game and the level editor).

const DEFS_DIR: String = "res://data/powerups"


## Every valid power-up, by id, sorted by id.
static func load_all() -> Dictionary[String, PowerUpDef]:
	var defs: Dictionary[String, PowerUpDef] = {}
	if not DirAccess.dir_exists_absolute(DEFS_DIR):
		return defs
	var files := ResourceLoader.list_directory(DEFS_DIR)
	files.sort()
	for file in files:
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var path := DEFS_DIR.path_join(file)
		var def := load(path) as PowerUpDef
		if def == null or def.id.is_empty() or def.effect == null:
			push_error("Not a valid PowerUpDef: " + path)
		elif defs.has(def.id):
			push_error("Duplicate power-up id \"%s\" in %s" % [def.id, path])
		else:
			defs[def.id] = def
	return defs
