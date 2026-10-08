class_name ComboLockEffect
extends PowerUpEffect

## Hitting the paddle does not reset the combo (losing a life still does).


func apply(ctx: GameContext) -> void:
	ctx.set_combo_lock(true)


func remove(ctx: GameContext) -> void:
	ctx.set_combo_lock(false)
