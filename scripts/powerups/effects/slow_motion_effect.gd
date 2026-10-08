class_name SlowMotionEffect
extends PowerUpEffect

## The whole game runs slower for a few seconds. The duration is in game time, so at half
## speed it lasts twice as long in real seconds.

const TIME_SCALE: float = 0.5


func apply(ctx: GameContext) -> void:
	ctx.set_time_scale(TIME_SCALE)


func remove(ctx: GameContext) -> void:
	ctx.set_time_scale(1.0)
