class_name RetroDraw
extends RefCounted

## Shared retro drawing helpers (bevelled blocks), used by bricks, the paddle and the frame.


## Filled block with a 1 px outline and a bevel: lighter top and left edges, darker bottom
## and right edges, like the bricks in DX-Ball.
static func bevel_rect(ci: CanvasItem, rect: Rect2, color: Color, bevel: float,
		lighten: float, darken: float, outline: Color) -> void:
	ci.draw_rect(rect, outline)
	var r := rect.grow(-1.0)
	ci.draw_rect(r, color)
	var light := color.lightened(lighten)
	var dark := color.darkened(darken)
	ci.draw_rect(Rect2(r.position.x, r.end.y - bevel, r.size.x, bevel), dark)
	ci.draw_rect(Rect2(r.end.x - bevel, r.position.y, bevel, r.size.y), dark)
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, bevel), light)
	ci.draw_rect(Rect2(r.position.x, r.position.y, bevel, r.size.y - bevel), light)


## The project's pixel font (theme default), for text drawn in _draw().
static func font() -> Font:
	var theme := ThemeDB.get_project_theme()
	if theme != null and theme.default_font != null:
		return theme.default_font
	return ThemeDB.fallback_font
