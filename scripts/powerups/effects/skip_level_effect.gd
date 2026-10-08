class_name SkipLevelEffect
extends PowerUpEffect

## The level counts as cleared at once (rare).


func apply(ctx: GameContext) -> void:
	ctx.complete_level()
