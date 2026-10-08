class_name TouchControls
extends Node

## Touch input for the game (DESIGN.md "Kontrole"): the paddle follows the finger, a short tap
## launches the ball (and continues after a level, like Space), and holding a finger down fires
## the paddle weapon.
##
## Following and firing come for free from Godot's "emulate mouse from touch" setting: a finger
## moves the emulated mouse (the paddle follows the mouse) and holds its left button (the `fire`
## action). Only the tap needs this node, because launching on touch-down would launch every time
## the player puts a finger down to move the paddle.

signal tapped

## A tap moves less than this (in game pixels) and is shorter than TAP_MAX_MSEC.
const TAP_MAX_MOVE: float = 24.0
const TAP_MAX_MSEC: int = 350
## Taps on the HUD bar at the top (the pause button) are not launches.
const TOP_BAR_HEIGHT: float = 64.0

## Touch index -> [start position, start time in msec].
var _touches: Dictionary[int, Array] = {}


func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch == null:
		return
	TouchInput.mark_touched()
	if touch.pressed:
		_touches[touch.index] = [touch.position, Time.get_ticks_msec()]
		return
	if not _touches.has(touch.index):
		return
	var start: Array = _touches[touch.index]
	_touches.erase(touch.index)
	var start_position: Vector2 = start[0]
	var duration: int = Time.get_ticks_msec() - int(start[1])
	if is_tap(start_position, touch.position, duration):
		tapped.emit()


## Pure rule, separate so it can be tested without real touches.
static func is_tap(start: Vector2, end: Vector2, duration_msec: int) -> bool:
	return start.y > TOP_BAR_HEIGHT and start.distance_to(end) <= TAP_MAX_MOVE \
			and duration_msec <= TAP_MAX_MSEC
