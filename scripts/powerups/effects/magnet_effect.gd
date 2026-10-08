class_name MagnetEffect
extends PowerUpEffect

## Falling capsules drift toward the paddle (the bad ones too).


func apply(ctx: GameContext) -> void:
	ctx.set_magnet(true)


func remove(ctx: GameContext) -> void:
	ctx.set_magnet(false)
