extends Node

## Global signal hub. Systems emit and listen here instead of holding references to each other.
## Registered as the `EventBus` autoload in project.godot.
##
## Signals are only declared here and emitted elsewhere, so the "unused signal" warning is
## silenced for each one.

@warning_ignore("unused_signal")
signal brick_destroyed(brick: Brick)

@warning_ignore("unused_signal")
signal ball_lost

@warning_ignore("unused_signal")
signal lives_changed(lives: int)

@warning_ignore("unused_signal")
signal level_cleared

@warning_ignore("unused_signal")
signal game_over
