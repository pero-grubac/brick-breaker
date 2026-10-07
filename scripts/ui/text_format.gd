class_name TextFormat
extends RefCounted

## Small text helpers shared by the HUD and the menus.


## 1234567 -> "1,234,567"
static func group_thousands(value: int) -> String:
	var digits := str(absi(value))
	var groups: PackedStringArray = []
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.insert(0, digits)
	return ("-" if value < 0 else "") + ",".join(groups)
