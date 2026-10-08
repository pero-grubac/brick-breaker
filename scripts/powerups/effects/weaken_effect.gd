class_name WeakenEffect
extends PowerUpEffect

## Every brick with at least 2 hp loses one. One-hit bricks are left alone, so the power-up
## never clears half the level at once.


func apply(ctx: GameContext) -> void:
	for brick in ctx.bricks():
		if not brick.brick_type.is_indestructible() and brick.hp >= 2:
			brick.damage(1)
