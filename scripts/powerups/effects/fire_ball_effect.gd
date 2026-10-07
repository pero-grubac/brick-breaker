class_name FireBallEffect
extends PowerUpEffect

## Balls burn through bricks without bouncing, steel included.


func apply(ctx: GameContext) -> void:
	ctx.set_fire(true)


func remove(ctx: GameContext) -> void:
	ctx.set_fire(false)
