class_name SlowBallEffect
extends PowerUpEffect

## Balls fly slower.

const SPEED_FACTOR: float = 0.7


func apply(ctx: GameContext) -> void:
	ctx.set_ball_speed_factor(SPEED_FACTOR)


func remove(ctx: GameContext) -> void:
	ctx.set_ball_speed_factor(1.0)
