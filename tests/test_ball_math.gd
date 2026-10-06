extends GutTest

## Unit tests for BallMath: minimum angle and paddle bounce direction.

const MIN_ANGLE := 20.0
const MAX_PADDLE_ANGLE := 65.0
const HALF_WIDTH := 60.0
const EPSILON := 0.0001


func _angle_from_horizontal(dir: Vector2) -> float:
	return rad_to_deg(atan2(absf(dir.y), absf(dir.x)))


func _angle_from_vertical(dir: Vector2) -> float:
	return rad_to_deg(dir.angle()) + 90.0


# --- enforce_min_angle ---

func test_steep_direction_is_unchanged() -> void:
	var dir := Vector2(1.0, -2.0).normalized()
	var result := BallMath.enforce_min_angle(dir, MIN_ANGLE)
	assert_almost_eq(result, dir, Vector2(EPSILON, EPSILON))


func test_result_is_normalized() -> void:
	var result := BallMath.enforce_min_angle(Vector2(30.0, -40.0), MIN_ANGLE)
	assert_almost_eq(result.length(), 1.0, EPSILON)


func test_shallow_up_right_is_raised_to_min_angle() -> void:
	var result := BallMath.enforce_min_angle(Vector2(1.0, -0.05), MIN_ANGLE)
	assert_almost_eq(_angle_from_horizontal(result), MIN_ANGLE, EPSILON)
	assert_gt(result.x, 0.0, "keeps moving right")
	assert_lt(result.y, 0.0, "keeps moving up")


func test_shallow_down_left_keeps_its_direction() -> void:
	var result := BallMath.enforce_min_angle(Vector2(-1.0, 0.1), MIN_ANGLE)
	assert_almost_eq(_angle_from_horizontal(result), MIN_ANGLE, EPSILON)
	assert_lt(result.x, 0.0, "keeps moving left")
	assert_gt(result.y, 0.0, "keeps moving down")


func test_horizontal_direction_is_pushed_up() -> void:
	var result := BallMath.enforce_min_angle(Vector2.LEFT, MIN_ANGLE)
	assert_almost_eq(_angle_from_horizontal(result), MIN_ANGLE, EPSILON)
	assert_lt(result.y, 0.0)


func test_exactly_min_angle_is_unchanged() -> void:
	var dir := Vector2.from_angle(deg_to_rad(-MIN_ANGLE))
	assert_almost_eq(BallMath.enforce_min_angle(dir, MIN_ANGLE), dir, Vector2(EPSILON, EPSILON))


# --- paddle_bounce_direction ---

func test_paddle_center_sends_ball_straight_up() -> void:
	var result := BallMath.paddle_bounce_direction(0.0, HALF_WIDTH, MAX_PADDLE_ANGLE)
	assert_almost_eq(result, Vector2.UP, Vector2(EPSILON, EPSILON))


func test_paddle_right_edge_gives_max_angle() -> void:
	var result := BallMath.paddle_bounce_direction(HALF_WIDTH, HALF_WIDTH, MAX_PADDLE_ANGLE)
	assert_almost_eq(_angle_from_vertical(result), MAX_PADDLE_ANGLE, EPSILON)


func test_paddle_left_edge_gives_negative_max_angle() -> void:
	var result := BallMath.paddle_bounce_direction(-HALF_WIDTH, HALF_WIDTH, MAX_PADDLE_ANGLE)
	assert_almost_eq(_angle_from_vertical(result), -MAX_PADDLE_ANGLE, EPSILON)


func test_paddle_halfway_gives_half_angle() -> void:
	var result := BallMath.paddle_bounce_direction(HALF_WIDTH / 2.0, HALF_WIDTH, MAX_PADDLE_ANGLE)
	assert_almost_eq(_angle_from_vertical(result), MAX_PADDLE_ANGLE / 2.0, EPSILON)


func test_paddle_hit_beyond_edge_is_clamped() -> void:
	var result := BallMath.paddle_bounce_direction(HALF_WIDTH * 1.5, HALF_WIDTH, MAX_PADDLE_ANGLE)
	assert_almost_eq(_angle_from_vertical(result), MAX_PADDLE_ANGLE, EPSILON)


func test_paddle_bounce_always_goes_up() -> void:
	for offset in [-90.0, -60.0, -10.0, 0.0, 10.0, 60.0, 90.0]:
		var result := BallMath.paddle_bounce_direction(offset, HALF_WIDTH, MAX_PADDLE_ANGLE)
		assert_lt(result.y, 0.0, "offset %s goes up" % offset)


func test_paddle_bounce_is_normalized() -> void:
	var result := BallMath.paddle_bounce_direction(25.0, HALF_WIDTH, MAX_PADDLE_ANGLE)
	assert_almost_eq(result.length(), 1.0, EPSILON)
