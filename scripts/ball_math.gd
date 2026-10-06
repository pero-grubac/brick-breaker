class_name BallMath
extends RefCounted

## Pure ball-direction math, kept separate from nodes so it can be unit tested.


## Returns a unit direction whose angle from the horizontal is at least `min_angle_deg`,
## keeping the horizontal and vertical direction (signs) of `direction`.
## A perfectly horizontal direction is pushed upwards.
static func enforce_min_angle(direction: Vector2, min_angle_deg: float) -> Vector2:
	var dir := direction.normalized()
	var min_angle := deg_to_rad(min_angle_deg)
	if atan2(absf(dir.y), absf(dir.x)) >= min_angle:
		return dir
	var sign_x := 1.0 if dir.x >= 0.0 else -1.0
	var sign_y := 1.0 if dir.y > 0.0 else -1.0
	return Vector2(sign_x * cos(min_angle), sign_y * sin(min_angle))
