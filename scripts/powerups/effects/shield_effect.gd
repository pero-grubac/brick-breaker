class_name ShieldEffect
extends PowerUpEffect

## A barrier under the paddle that bounces the ball back once. Stays until it is used,
## even across lives and levels; another shield adds one more hit.


func apply(ctx: GameContext) -> void:
	ctx.add_shield()
