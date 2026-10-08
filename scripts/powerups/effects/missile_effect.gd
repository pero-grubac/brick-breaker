class_name MissileEffect
extends PowerUpEffect

## The paddle gets AMMO missiles; each one destroys the whole row of the brick it hits.
## The effect ends when the timer runs out or the last missile is fired.

const AMMO: int = 3


func apply(ctx: GameContext) -> void:
	ctx.set_weapon(&"missile", AMMO)


func remove(ctx: GameContext) -> void:
	ctx.set_weapon(&"")


func tick(ctx: GameContext, _delta: float) -> void:
	if ctx.weapon_ammo() == 0:
		time_left = 0.0
