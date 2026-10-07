class_name MultiballEffect
extends PowerUpEffect

## Every flying ball splits into three: the original plus two at +-SPLIT_ANGLE_DEG.

const SPLIT_ANGLE_DEG: float = 30.0


func apply(ctx: GameContext) -> void:
	for ball in ctx.balls():
		for angle in [-SPLIT_ANGLE_DEG, SPLIT_ANGLE_DEG]:
			ctx.spawn_ball(ball.position, ball.velocity.rotated(deg_to_rad(angle)))
