class_name GhostBricksEffect
extends PowerUpEffect

## Every brick fades almost invisible for a few seconds. They still collide.


func apply(ctx: GameContext) -> void:
	ctx.set_bricks_hidden(true)


func remove(ctx: GameContext) -> void:
	ctx.set_bricks_hidden(false)
