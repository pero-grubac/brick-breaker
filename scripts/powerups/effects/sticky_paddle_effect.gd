class_name StickyPaddleEffect
extends PowerUpEffect

## Balls stick to the paddle; `launch` releases them in the paddle-angle direction.


func apply(ctx: GameContext) -> void:
	ctx.set_sticky(true)


func remove(ctx: GameContext) -> void:
	ctx.set_sticky(false)
