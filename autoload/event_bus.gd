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
signal level_started(level_number: int, level_count: int, level_name: String)

@warning_ignore("unused_signal")
signal level_cleared

@warning_ignore("unused_signal")
signal game_over

@warning_ignore("unused_signal")
signal score_changed(score: int)

@warning_ignore("unused_signal")
signal combo_changed(combo: float)

@warning_ignore("unused_signal")
signal powerup_collected(powerup_id: String)

@warning_ignore("unused_signal")
signal paused_changed(paused: bool)

## Active power-ups as short display lines ("Long paddle 12"), sent when they change.
@warning_ignore("unused_signal")
signal active_powerups_changed(lines: PackedStringArray)
