class_name DarknessEffect
extends PowerUpEffect

## The arena goes dark except around the balls and the paddle.


func apply(ctx: GameContext) -> void:
	ctx.set_darkness(true)


func remove(ctx: GameContext) -> void:
	ctx.set_darkness(false)
