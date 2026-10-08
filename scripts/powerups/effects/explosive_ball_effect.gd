class_name ExplosiveBallEffect
extends PowerUpEffect

## Every brick the ball hits explodes a little: the bricks around it take one damage.


func apply(ctx: GameContext) -> void:
	ctx.set_explosive(true)


func remove(ctx: GameContext) -> void:
	ctx.set_explosive(false)
