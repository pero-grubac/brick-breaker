class_name ReverseControlsEffect
extends PowerUpEffect

## Left and right are swapped (keyboard, gamepad and mouse).


func apply(ctx: GameContext) -> void:
	ctx.paddle.reversed = true


func remove(ctx: GameContext) -> void:
	ctx.paddle.reversed = false
