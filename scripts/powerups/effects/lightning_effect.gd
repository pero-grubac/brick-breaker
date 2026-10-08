class_name LightningEffect
extends PowerUpEffect

## Lightning strikes STRIKES random breakable bricks that count for the clear and destroys them.

const STRIKES: int = 6


func apply(ctx: GameContext) -> void:
	var targets: Array[Brick] = []
	for brick in ctx.bricks():
		if brick.counts_for_clear() and not brick.brick_type.is_indestructible():
			targets.append(brick)
	targets.shuffle()
	for brick in targets.slice(0, STRIKES):
		EventBus.lightning_struck.emit(brick.global_position)
		brick.destroy()
