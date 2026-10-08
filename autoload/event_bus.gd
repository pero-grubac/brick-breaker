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

## Points just added for one brick, and where (for the floating "+75").
@warning_ignore("unused_signal")
signal points_scored(points: int, at: Vector2)

@warning_ignore("unused_signal")
signal powerup_collected(powerup_id: String)

@warning_ignore("unused_signal")
signal paused_changed(paused: bool)

## The ball bounced off "paddle" or "wall" (bricks have their own signals).
@warning_ignore("unused_signal")
signal ball_bounced(surface: StringName)

@warning_ignore("unused_signal")
signal ball_launched

## A brick was hit but not destroyed (hard brick lost hp, or steel).
@warning_ignore("unused_signal")
signal brick_damaged(brick: Brick)

## A TNT brick exploded at this position.
@warning_ignore("unused_signal")
signal explosion(at: Vector2)

## The ball went into a portal at `from` and came out at `to`.
@warning_ignore("unused_signal")
signal portal_used(from: Vector2, to: Vector2)

## A spawner brick wants a new brick of `type_id` in `cell` (Game decides).
@warning_ignore("unused_signal")
signal brick_spawn_requested(cell: Vector2i, type_id: String)

@warning_ignore("unused_signal")
signal life_gained

## The last level of a set was cleared (after level_cleared).
@warning_ignore("unused_signal")
signal set_completed

## A level of a set was cleared (SaveManager unlocks it as a start level).
@warning_ignore("unused_signal")
signal level_completed(set_id: String, level_index: int)

## A run ended (game over or set complete) with this final score.
@warning_ignore("unused_signal")
signal run_ended(set_id: String, score: int)

## Active power-ups as short display lines ("Long paddle 12"), sent when they change.
@warning_ignore("unused_signal")
signal active_powerups_changed(lines: PackedStringArray)

## The "lightning" power-up hit a brick at this position (GameEffects draws the bolt).
@warning_ignore("unused_signal")
signal lightning_struck(at: Vector2)

## The game speed changed (slow motion); 1.0 = normal. Hit stop returns to this value.
@warning_ignore("unused_signal")
signal time_scale_changed(scale: float)
