class_name ScoreTracker
extends RefCounted

## Score and combo rules (DESIGN.md "Bodovanje, combo, životi i progres"). Pure logic: Game
## feeds it events and reads the results.
##
## Points per brick = brick points x current combo. The combo starts at x1, grows by 0.5 for
## every 3 bricks broken without the ball touching the paddle, up to x5, and resets when the
## ball hits the paddle or a life is lost. Every 50,000 points earns an extra life.

const COMBO_START: float = 1.0
const COMBO_STEP: float = 0.5
const COMBO_MAX: float = 5.0
const BRICKS_PER_COMBO_STEP: int = 3
const EXTRA_LIFE_EVERY: int = 50000

var score: int = 0
var combo: float = COMBO_START
## Bricks broken since the combo last reset.
var combo_bricks: int = 0
## Score at which the next extra life is earned.
var next_extra_life_at: int = EXTRA_LIFE_EVERY


## Adds the points for one broken brick. Returns how many extra lives were earned (usually 0).
func add_brick(points: int) -> int:
	score += roundi(points * combo)
	combo_bricks += 1
	if combo_bricks % BRICKS_PER_COMBO_STEP == 0:
		combo = minf(combo + COMBO_STEP, COMBO_MAX)
	var lives_earned := 0
	while score >= next_extra_life_at:
		lives_earned += 1
		next_extra_life_at += EXTRA_LIFE_EVERY
	return lives_earned


## Ball touched the paddle (or a life was lost): back to x1.
func reset_combo() -> void:
	combo = COMBO_START
	combo_bricks = 0
