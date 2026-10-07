class_name FastBallEffect
extends PowerUpEffect

## Negative: balls fly faster.

const SPEED_FACTOR: float = 1.35


func apply(ctx: GameContext) -> void:
	ctx.set_ball_speed_factor(SPEED_FACTOR)


func remove(ctx: GameContext) -> void:
	ctx.set_ball_speed_factor(1.0)
