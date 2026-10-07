class_name ShortPaddleEffect
extends PowerUpEffect

## Negative: the paddle gets narrower.

const WIDTH_FACTOR: float = 0.6


func apply(ctx: GameContext) -> void:
	ctx.paddle.width = ctx.paddle_base_width * WIDTH_FACTOR


func remove(ctx: GameContext) -> void:
	ctx.paddle.width = ctx.paddle_base_width
