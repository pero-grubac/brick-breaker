class_name SmallBallEffect
extends PowerUpEffect

## Balls get tiny and hard to follow.

const RADIUS_FACTOR: float = 0.6


func apply(ctx: GameContext) -> void:
	ctx.set_ball_radius_factor(RADIUS_FACTOR)


func remove(ctx: GameContext) -> void:
	ctx.set_ball_radius_factor(1.0)
