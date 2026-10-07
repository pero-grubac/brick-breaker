class_name LongPaddleEffect
extends PowerUpEffect

## The paddle gets wider.

const WIDTH_FACTOR: float = 1.5


func apply(ctx: GameContext) -> void:
	ctx.paddle.width = ctx.paddle_base_width * WIDTH_FACTOR


func remove(ctx: GameContext) -> void:
	ctx.paddle.width = ctx.paddle_base_width
