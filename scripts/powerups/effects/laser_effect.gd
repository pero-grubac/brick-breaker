class_name LaserEffect
extends PowerUpEffect

## The paddle shoots two laser bolts while `fire` is held.


func apply(ctx: GameContext) -> void:
	ctx.set_weapon(&"laser")


func remove(ctx: GameContext) -> void:
	ctx.set_weapon(&"")
