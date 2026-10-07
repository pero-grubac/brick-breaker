class_name PowerUpEffect
extends RefCounted

## Base class for power-up behavior. PowerUpManager creates one instance per activation,
## calls apply() once, tick() every frame while active and remove() when it ends.
## Effects change the game only through GameContext.

var def: PowerUpDef = null
## Seconds left for timed effects; ignored when def.duration is 0.
var time_left: float = 0.0


func apply(_ctx: GameContext) -> void:
	pass


func remove(_ctx: GameContext) -> void:
	pass


func tick(_ctx: GameContext, _delta: float) -> void:
	pass
