class_name PointsX2Effect
extends PowerUpEffect

## Double points. Stacks: two active copies give x4.

const FACTOR: float = 2.0


func apply(ctx: GameContext) -> void:
	ctx.multiply_score(FACTOR)


func remove(ctx: GameContext) -> void:
	ctx.multiply_score(1.0 / FACTOR)
