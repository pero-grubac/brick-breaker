class_name PowerUpRules
extends RefCounted

## Stack rules (DESIGN.md "Pravila kombinovanja"). Pure logic: given the active effects and a
## newly collected power-up, says what to remove, what to refresh and whether to apply it.
##
## Groups are always exclusive: picking up a power-up removes active effects of the *same
## exclusive_group with a different id* (long paddle ends short paddle), whatever the rule.
## INSTANT power-ups only act once and never touch active effects.


class Resolution:
	## Active effects to remove (call remove() on each).
	var remove: Array[PowerUpEffect] = []
	## Active effect whose timer restarts, or null.
	var refresh: PowerUpEffect = null
	## Whether to create and apply a new effect.
	var apply_new: bool = false
	## Whether the new effect stays in the active list (false for INSTANT).
	var keep_active: bool = true


static func resolve(active: Array[PowerUpEffect], def: PowerUpDef) -> Resolution:
	var r := Resolution.new()
	if def.stack_rule == PowerUpDef.StackRule.INSTANT:
		r.apply_new = true
		r.keep_active = false
		return r

	for effect in active:
		var other := effect.def
		var same_group := not def.exclusive_group.is_empty() \
				and other.exclusive_group == def.exclusive_group
		if same_group and other.id != def.id:
			r.remove.append(effect)

	var same_id: Array[PowerUpEffect] = []
	for effect in active:
		if effect.def.id == def.id:
			same_id.append(effect)

	match def.stack_rule:
		PowerUpDef.StackRule.REFRESH:
			if same_id.is_empty():
				r.apply_new = true
			else:
				r.refresh = same_id[0]
		PowerUpDef.StackRule.STACK:
			r.apply_new = true
		PowerUpDef.StackRule.REPLACE:
			r.remove.append_array(same_id)
			r.apply_new = true
	return r
