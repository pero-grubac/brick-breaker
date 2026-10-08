class_name IcePaddleEffect
extends PowerUpEffect

## The paddle slides: it speeds up and slows down slowly instead of stopping at once.


func apply(ctx: GameContext) -> void:
	ctx.paddle.ice = true


func remove(ctx: GameContext) -> void:
	ctx.paddle.ice = false
