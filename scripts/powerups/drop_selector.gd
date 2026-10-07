class_name DropSelector
extends RefCounted

## Drop rules (DESIGN.md "Drop logika"). Pure logic: the random numbers come in as `roll`
## values in [0, 1), so tests can pass fixed numbers.
##
## Chance = brick drop_chance x level drop_modifier, plus a small bonus per combo step.
## The power-up is then a weighted pick among the ones the level allows.

## Extra drop chance per combo step above x1 (x1.5 = 1 step, x5 = 8 steps).
const COMBO_BONUS_PER_STEP: float = 0.02


static func drop_chance(brick_chance: float, level_modifier: float, combo: float) -> float:
	var base := brick_chance * level_modifier
	if base <= 0.0:
		return 0.0  # bricks or levels with no drops stay at zero, whatever the combo
	var steps := maxf(combo - ScoreTracker.COMBO_START, 0.0) / ScoreTracker.COMBO_STEP
	return clampf(base + steps * COMBO_BONUS_PER_STEP, 0.0, 1.0)


static func should_drop(chance: float, roll: float) -> bool:
	return roll < chance


## The power-ups a level allows: `allowed` is "all" or a list of ids; `banned` always wins.
static func candidates(all_defs: Array[PowerUpDef], allowed: Variant, banned: PackedStringArray,
		positive_only: bool = false) -> Array[PowerUpDef]:
	var result: Array[PowerUpDef] = []
	for def in all_defs:
		if def.weight <= 0.0 or def.id in banned:
			continue
		if allowed is PackedStringArray and not def.id in allowed:
			continue
		if positive_only and def.is_negative:
			continue
		result.append(def)
	return result


## Weighted pick: a def with weight 2 is twice as likely as one with weight 1.
## Returns null when there is nothing to pick from.
static func pick(defs: Array[PowerUpDef], roll: float) -> PowerUpDef:
	var total := 0.0
	for def in defs:
		total += def.weight
	if total <= 0.0:
		return null
	var target := roll * total
	for def in defs:
		target -= def.weight
		if target < 0.0:
			return def
	return defs[-1]  # roll == 1.0 or rounding at the very end
