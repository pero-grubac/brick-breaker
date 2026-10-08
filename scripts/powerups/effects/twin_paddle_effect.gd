class_name TwinPaddleEffect
extends PowerUpEffect

## A second paddle floats above the main one and follows it. Balls pass through it from
## below and bounce off it from above.


func apply(ctx: GameContext) -> void:
	ctx.set_twin_paddle(true)


func remove(ctx: GameContext) -> void:
	ctx.set_twin_paddle(false)
