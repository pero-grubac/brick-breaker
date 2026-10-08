class_name MegaBallEffect
extends PowerUpEffect

## Fills the arena up to TOTAL_BALLS balls, fanned out upwards from the first flying ball.

const TOTAL_BALLS: int = 8
const FAN_DEG: float = 140.0


func apply(ctx: GameContext) -> void:
	var balls := ctx.balls()
	if balls.is_empty():
		return
	var source := balls[0]
	var missing := TOTAL_BALLS - balls.size()
	for i in missing:
		var t := (i + 0.5) / missing
		var direction := Vector2.UP.rotated(deg_to_rad((t - 0.5) * FAN_DEG))
		ctx.spawn_ball(source.position, direction)
