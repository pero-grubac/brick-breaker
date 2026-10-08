class_name DeathEffect
extends PowerUpEffect

## You lose a life right away, as if every ball fell out.


func apply(ctx: GameContext) -> void:
	ctx.lose_life()
