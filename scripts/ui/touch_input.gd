class_name TouchInput
extends RefCounted

## Whether the player uses a touch screen, so hints can say "Tap" instead of "Press Space".
## True from the start on phones and tablets (also mobile browsers), and on any device as soon as
## a real touch arrives.

static var _touched: bool = false


static func active() -> bool:
	return _touched or OS.has_feature("mobile") or OS.has_feature("web_android") \
			or OS.has_feature("web_ios")


static func mark_touched() -> void:
	_touched = true
