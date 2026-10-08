class_name PortalBehavior
extends BrickBehavior

## Indestructible portal: a ball that hits it comes out of the partner portal, flying in the
## same direction. Portals pair up in reading order (1st with 2nd, 3rd with 4th...); a single
## leftover portal pairs with the first one. A lone portal acts like steel.

## Extra gap between the partner portal and the ball when it comes out.
const EXIT_GAP: float = 3.0
## After a teleport the ball cannot use a portal again for this long (it bounces instead).
## A safety net against any portal-to-portal loop.
const COOLDOWN_MSEC: int = 150
const COOLDOWN_META: StringName = &"portal_cooldown_until"


func on_hit(brick: Brick, ball: Ball) -> bool:
	if ball == null or Time.get_ticks_msec() < int(ball.get_meta(COOLDOWN_META, 0)):
		return false
	var partner := find_partner(brick)
	if partner == null:
		return false
	var direction := ball.velocity.normalized()
	ball.global_position = exit_position(partner, direction, ball.radius)
	ball.reset_physics_interpolation()
	ball.set_meta(COOLDOWN_META, Time.get_ticks_msec() + COOLDOWN_MSEC)
	EventBus.portal_used.emit(brick.global_position, partner.global_position)
	return true


func find_partner(brick: Brick) -> Brick:
	if brick.grid == null:
		return null
	var portals: Array[Brick] = []
	for other in brick.grid.bricks():
		if other.brick_type.id == brick.brick_type.id:
			portals.append(other)
	return partner_of(portals, brick)


## Pairing rule, separate so it can be tested without a running game.
static func partner_of(portals: Array[Brick], brick: Brick) -> Brick:
	if portals.size() < 2:
		return null
	portals.sort_custom(func(a: Brick, b: Brick) -> bool:
		return a.cell.y < b.cell.y or (a.cell.y == b.cell.y and a.cell.x < b.cell.x))
	var index := portals.find(brick)
	if index == -1:
		return null
	if index == portals.size() - 1 and portals.size() % 2 == 1:
		return portals[0]
	return portals[index ^ 1]


## Where the ball comes out: along `direction` from the partner's center, far enough that the
## whole ball (not just its center) is clear of the partner. The partner rectangle is grown by
## the ball radius, and the ball center is placed just past the nearest edge of that rectangle.
static func exit_position(partner: Brick, direction: Vector2, radius: float) -> Vector2:
	var reach := partner.size / 2.0 + Vector2(radius, radius)
	var tx := reach.x / absf(direction.x) if not is_zero_approx(direction.x) else INF
	var ty := reach.y / absf(direction.y) if not is_zero_approx(direction.y) else INF
	return partner.global_position + direction * (minf(tx, ty) + EXIT_GAP)
