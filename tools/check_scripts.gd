extends SceneTree

## Compiles every .gd file in the project and exits with code 1 if any fails.
## Unlike `--check-only`, this runs after autoloads are registered, so scripts that use
## autoload names (EventBus, ...) compile correctly.
##
## Usage: godot --headless --path . -s res://tools/check_scripts.gd

const SKIP_DIRS: Array[String] = ["res://addons"]


func _initialize() -> void:
	var paths: Array[String] = []
	_collect("res://", paths)
	# Reloading the running script itself crashes the VM.
	paths.erase((get_script() as Script).resource_path)
	var failed := 0
	for path in paths:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			failed += 1
			print("FAILED ", path)
	print("checked %d scripts, %d failed" % [paths.size(), failed])
	quit(1 if failed > 0 else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	if dir_path.trim_suffix("/") in SKIP_DIRS:
		return
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		if not sub.begins_with("."):  # .godot, .git
			_collect(dir_path.path_join(sub), out)
