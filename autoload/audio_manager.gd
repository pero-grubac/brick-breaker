extends Node

## Music and sound effects (autoload `AudioManager`). Listens to EventBus and plays the matching
## sound, so game systems never deal with audio. Music goes to the "Music" bus and effects to
## "SFX"; their volumes come from the settings (SaveManager). Every Button in the game gets a
## click sound automatically.
##
## To change a sound, change its file in SFX below (sources: assets/sound/kenney/SOURCES.txt
## and tools/audio/generate_audio.py).

const SFX: Dictionary[StringName, String] = {
	&"brick_break": "res://assets/sound/generated/brick_break.wav",
	&"brick_crack": "res://assets/sound/generated/brick_crack.wav",
	&"paddle_hit": "res://assets/sound/generated/paddle_hit.wav",
	&"wall_hit": "res://assets/sound/generated/wall_hit.wav",
	&"explosion": "res://assets/sound/generated/explosion.wav",
	&"burn": "res://assets/sound/generated/burn.wav",
	&"steel_hit": "res://assets/sound/kenney/steel_hit.ogg",
	&"powerup_good": "res://assets/sound/kenney/powerup_good.ogg",
	&"powerup_bad": "res://assets/sound/kenney/powerup_bad.ogg",
	&"launch": "res://assets/sound/kenney/launch.ogg",
	&"life_lost": "res://assets/sound/kenney/life_lost.ogg",
	&"extra_life": "res://assets/sound/kenney/extra_life.ogg",
	&"game_over": "res://assets/sound/kenney/game_over.ogg",
	&"level_clear": "res://assets/sound/kenney/level_clear.ogg",
	&"set_complete": "res://assets/sound/kenney/set_complete.ogg",
	&"ui_click": "res://assets/sound/kenney/ui_click.ogg",
	&"ui_move": "res://assets/sound/kenney/ui_move.ogg",
}
const MUSIC: Dictionary[StringName, String] = {
	&"menu": "res://assets/music/menu.ogg",
	&"level_a": "res://assets/music/level_a.ogg",
	&"level_b": "res://assets/music/level_b.ogg",
}
## Level music when the level file does not choose one: alternates by level number.
const LEVEL_TRACKS: Array[StringName] = [&"level_a", &"level_b"]

const VOICES: int = 16
## Brick break pitch rises with the combo (DESIGN.md: "the best single trick for game feel").
const COMBO_PITCH_STEP: float = 0.06
const MAX_COMBO_PITCH: float = 1.6
const PITCH_JITTER: float = 0.03
const MUSIC_FADE: float = 0.6
## Quiet UI sounds.
const UI_VOLUME_DB: float = -8.0
const SET_COMPLETE_DELAY: float = 1.6
const MUSIC_START_DELAY: float = 0.15
## Seconds to wait after stopping audio before quitting.
const QUIT_WAIT: float = 0.2

var _streams: Dictionary[StringName, AudioStream] = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music: AudioStreamPlayer = null
var _music_track: StringName = &""
var _music_tween: Tween = null
var _combo: float = 1.0
var _negative_powerups: Dictionary[String, bool] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SFX:
		_streams[key] = load(SFX[key])
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_voices.append(player)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)

	var defs := PowerUpCatalog.load_all()
	for id in defs:
		_negative_powerups[id] = defs[id].is_negative

	EventBus.combo_changed.connect(func(combo: float) -> void: _combo = combo)
	EventBus.brick_destroyed.connect(_on_brick_destroyed)
	EventBus.brick_damaged.connect(_on_brick_damaged)
	EventBus.ball_bounced.connect(_on_ball_bounced)
	EventBus.ball_launched.connect(play.bind(&"launch"))
	EventBus.explosion.connect(func(_at: Vector2) -> void: play(&"explosion"))
	EventBus.powerup_collected.connect(_on_powerup_collected)
	EventBus.life_gained.connect(play.bind(&"extra_life"))
	EventBus.ball_lost.connect(play.bind(&"life_lost"))
	EventBus.game_over.connect(play.bind(&"game_over"))
	EventBus.level_cleared.connect(play.bind(&"level_clear"))
	EventBus.set_completed.connect(_on_set_completed)
	get_tree().node_added.connect(_on_node_added)
	# Closing the window goes through quit_game(), so audio can stop cleanly first.
	get_tree().auto_accept_quit = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


## Stops all audio, gives the audio thread a moment to release its playback objects,
## then quits. Quitting while a stream plays would leave them behind ("leaked instances").
func quit_game() -> void:
	_stop_all()
	await get_tree().create_timer(QUIT_WAIT, true, false, true).timeout
	get_tree().quit()


func _stop_all() -> void:
	if _music_tween != null:
		_music_tween.kill()
	_music.stop()
	_music.stream = null
	_music_track = &""
	for voice in _voices:
		voice.stop()
		voice.stream = null


## Plays an effect. `pitch` > 1 is higher.
func play(sound: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		push_warning("Unknown sound: " + sound)
		return
	var player := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


## Switches music with a short fade. Playing the current track again does nothing.
func play_music(track: StringName) -> void:
	if track == _music_track and _music.playing:
		return
	var path: String = MUSIC.get(track, "")
	if path.is_empty():
		return
	_music_track = track
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -40.0, MUSIC_FADE / 2.0)
	else:
		# A short wait lets the new scene settle (and keeps instant --quit checks clean).
		_music_tween.tween_interval(MUSIC_START_DELAY)
	_music_tween.tween_callback(func() -> void:
		_music.stream = load(path)
		_music.volume_db = 0.0
		_music.play())


## Music for a level: the level's own "music" setting if it names a known track, otherwise
## the tracks alternate by level number.
func play_level_music(level_music: String, level_index: int) -> void:
	if MUSIC.has(StringName(level_music)):
		play_music(StringName(level_music))
	else:
		play_music(LEVEL_TRACKS[level_index % LEVEL_TRACKS.size()])


func stop_music() -> void:
	_music.stop()
	_music_track = &""


func _on_brick_destroyed(_brick: Brick) -> void:
	var pitch := minf(1.0 + (_combo - 1.0) / ScoreTracker.COMBO_STEP * COMBO_PITCH_STEP,
			MAX_COMBO_PITCH)
	play(&"brick_break", pitch + randf_range(-PITCH_JITTER, PITCH_JITTER))


func _on_brick_damaged(brick: Brick) -> void:
	if brick.brick_type.is_indestructible():
		play(&"steel_hit", randf_range(0.95, 1.05), -4.0)
	else:
		play(&"brick_crack", randf_range(0.95, 1.05))


func _on_ball_bounced(surface: StringName) -> void:
	match surface:
		&"paddle":
			play(&"paddle_hit")
		&"wall":
			play(&"wall_hit", randf_range(0.97, 1.03), -6.0)


## The last level's "level clear" jingle plays first; the set fanfare follows it.
func _on_set_completed() -> void:
	await get_tree().create_timer(SET_COMPLETE_DELAY).timeout
	play(&"set_complete")


func _on_powerup_collected(powerup_id: String) -> void:
	play(&"powerup_bad" if _negative_powerups.get(powerup_id, false) else &"powerup_good")


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null:
		return
	button.pressed.connect(func() -> void: play(&"ui_click", 1.0, UI_VOLUME_DB))
	button.focus_entered.connect(func() -> void:
		if button.is_visible_in_tree():
			play(&"ui_move", 1.0, UI_VOLUME_DB - 4.0))
