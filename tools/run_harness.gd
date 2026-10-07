extends SceneTree

## Runs a gameplay test harness: a script that `extends Node`, does its work from _ready()
## and calls get_tree().quit() when done. The harness is loaded only after startup, when the
## autoloads (EventBus, LevelLoader) exist, so it may use every project class.
##
## Usage: godot --headless --fixed-fps 60 --path . -s res://tools/run_harness.gd -- <harness.gd>


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Usage: -s res://tools/run_harness.gd -- <path to harness .gd>")
		quit(1)
		return
	var script := load(args[0]) as GDScript
	if script == null or not script.can_instantiate():
		push_error("Cannot load harness: " + args[0])
		quit(1)
		return
	root.add_child.call_deferred(script.new())
