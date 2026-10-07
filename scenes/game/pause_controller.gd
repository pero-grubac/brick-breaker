class_name PauseController
extends Node

## Pauses the game on the `pause` action and when the window loses focus (or the app goes to
## the background on mobile). Runs while the tree is paused, so it can also unpause.
## Announces changes through EventBus.paused_changed; the HUD shows the overlay.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		set_paused(true)


func set_paused(paused: bool) -> void:
	if get_tree().paused == paused:
		return
	get_tree().paused = paused
	EventBus.paused_changed.emit(paused)


func _exit_tree() -> void:
	# Never leave the tree paused behind us (e.g. reload while paused).
	get_tree().paused = false
