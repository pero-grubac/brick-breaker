class_name DrunkBallEffect
extends PowerUpEffect

## Balls weave left and right while flying.


func apply(ctx: GameContext) -> void:
	ctx.set_drunk(true)


func remove(ctx: GameContext) -> void:
	ctx.set_drunk(false)
