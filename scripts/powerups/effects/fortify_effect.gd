class_name FortifyEffect
extends PowerUpEffect

## Every breakable brick gets +1 hp, at most one above its type's normal hp.


func apply(ctx: GameContext) -> void:
	for brick in ctx.bricks():
		if not brick.brick_type.is_indestructible():
			brick.heal(1, brick.brick_type.hp + 1)
