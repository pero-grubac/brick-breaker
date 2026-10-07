class_name ExtraLifeEffect
extends PowerUpEffect

## One more life (instant).


func apply(ctx: GameContext) -> void:
	ctx.add_life()
