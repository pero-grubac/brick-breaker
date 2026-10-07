extends CanvasLayer

## CRT scanline overlay on top of every scene (autoload `CrtOverlay`). Shown or hidden by the
## "CRT effect" setting.


func _ready() -> void:
	SaveManager.settings_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	visible = SaveManager.data.crt
