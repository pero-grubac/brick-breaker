class_name BigBallEffect
extends PowerUpEffect

## Balls get bigger (easier to hit bricks, the paddle still bounces them normally).

const RADIUS_FACTOR: float = 1.6


func apply(ctx: GameContext) -> void:
	ctx.set_ball_radius_factor(RADIUS_FACTOR)


func remove(ctx: GameContext) -> void:
	ctx.set_ball_radius_factor(1.0)
