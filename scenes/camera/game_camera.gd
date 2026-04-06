extends Camera2D

enum CameraMode { FOLLOW_PLAYER, FOLLOW_BALL }

const BALL_STATE_IN_FLIGHT := 3
const BALL_STATE_RESTING   := 4

@export var player_smoothing_speed: float       = 8.0
@export var player_horizontal_deadzone: float   = 80.0
@export var player_vertical_smoothing: float    = 5.0
@export var transition_speed: float             = 1200.0
@export var max_transition_duration: float      = 0.6
@export var shot_direction: int                 = 1   # -1 or 1, locked at shot time

@export_group("Ball Follow")
@export var ball_horizontal_smoothing_speed: float = 8.0
@export var ball_vertical_smoothing_speed: float   = 6.0
@export var ball_velocity_threshold: float         = 150.0
@export var ball_displacement_threshold: float     = 30.0

@export_group("Debug")
@export var show_debug_logs: bool = true

var _mode: CameraMode = CameraMode.FOLLOW_PLAYER
var _frozen: bool = false

var _player: Node2D = null
var _ball: Node2D   = null

# Shared tracked Y — used in FOLLOW_PLAYER to avoid jumps on mode switch.
var _tracked_y: float = 0.0

# FOLLOW_BALL: desired camera position; smoothed toward each frame.
var _camera_target: Vector2 = Vector2.ZERO

# Transition back to player state.
var _transitioning: bool          = false
var _transition_start: Vector2    = Vector2.ZERO
var _transition_target: Vector2   = Vector2.ZERO
var _transition_progress: float   = 0.0
var _transition_duration: float   = 0.0


func _ready() -> void:
	add_to_group("game_camera")

	position_smoothing_enabled = true
	position_smoothing_speed   = player_smoothing_speed

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
		global_position = _player.global_position
		_tracked_y      = _player.global_position.y

	var balls := get_tree().get_nodes_in_group("golf_ball")
	if balls.size() > 0:
		_ball = balls[0]
		_ball.ball_state_changed.connect(_on_ball_state_changed)

	if show_debug_logs:
		print("[Camera] state: ready, FOLLOW_PLAYER")


# ── Signal handler ────────────────────────────────────────────────────────────

func _on_ball_state_changed(new_state: int) -> void:
	match new_state:
		BALL_STATE_IN_FLIGHT:
			if show_debug_logs:
				print("[Camera] state: IN_FLIGHT -> FOLLOW_BALL")
			_mode           = CameraMode.FOLLOW_BALL
			shot_direction  = int(sign(_ball.linear_velocity.x))
			if shot_direction == 0:
				shot_direction = 1
			_camera_target  = global_position

		BALL_STATE_RESTING:
			if _frozen:
				return
			if show_debug_logs:
				print("[Camera] state: RESTING -> starting transition to player")
			_start_transition_to_player()


# ── Main process ──────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	match _mode:
		CameraMode.FOLLOW_PLAYER:
			if _transitioning:
				_update_transition(delta)
			else:
				_follow_player(delta)

		CameraMode.FOLLOW_BALL:
			_follow_ball(delta)


# ── FOLLOW_PLAYER ─────────────────────────────────────────────────────────────

func _follow_player(delta: float) -> void:
	if _player == null:
		return

	var player_pos := _player.global_position

	# Horizontal deadzone — only move camera X when player leaves the band.
	var dx := player_pos.x - global_position.x
	if abs(dx) > player_horizontal_deadzone:
		global_position.x = player_pos.x - sign(dx) * player_horizontal_deadzone

	# Vertical — lerp with separate (lower) responsiveness to damp small jumps.
	_tracked_y         = lerpf(_tracked_y, player_pos.y, player_vertical_smoothing * delta)
	global_position.y  = _tracked_y


# ── FOLLOW_BALL ───────────────────────────────────────────────────────────────

func _follow_ball(delta: float) -> void:
	if _ball == null:
		return

	var ball_pos   := _ball.global_position
	var half_width := get_viewport_rect().size.x * 0.5

	# Horizontal target — track ball in both directions.
	# The threshold that previously gated this on the right half only
	# prevented the camera from following leftward, so it is removed.
	# The horizontal lerp below provides the gradual-feel equivalent.
	_camera_target.x = ball_pos.x

	# Vertical target — gated to suppress jitter from small bounces.
	# Update only when the ball is moving fast enough OR far enough from target.
	var ball_vel_y   := absf(_ball.linear_velocity.y)
	var displacement := absf(ball_pos.y - _camera_target.y)
	if ball_vel_y > ball_velocity_threshold or displacement > ball_displacement_threshold:
		_camera_target.y = ball_pos.y
	elif show_debug_logs:
		print("[Camera] vertical gate blocked — velocity: ",
				_ball.linear_velocity.y, " displacement: ", displacement)

	# Clamp target to level bounds before smoothing so the camera never
	# lerps outside the hole limits.
	_camera_target.x = clampf(_camera_target.x,
			float(limit_left)  + half_width,
			float(limit_right) - half_width)

	# Smooth toward target independently per axis.
	global_position.x = lerpf(global_position.x, _camera_target.x, ball_horizontal_smoothing_speed * delta)
	global_position.y = lerpf(global_position.y, _camera_target.y, ball_vertical_smoothing_speed * delta)


# ── Transition back to player ─────────────────────────────────────────────────

func _start_transition_to_player() -> void:
	_mode = CameraMode.FOLLOW_PLAYER

	if _player == null:
		if show_debug_logs:
			print("[Camera] state: no player found, FOLLOW_PLAYER immediately")
		return

	_transitioning       = true
	_transition_start    = global_position
	_transition_target   = _player.global_position
	_transition_progress = 0.0

	var dist := _transition_start.distance_to(_transition_target)
	if dist < 1.0:
		_finish_transition()
		return

	_transition_duration = minf(dist / transition_speed, max_transition_duration)

	# Disable built-in smoothing so the timed lerp drives exact duration.
	position_smoothing_enabled = false
	if show_debug_logs:
		print("[Camera] state: transition %.0fpx over %.2fs" % [dist, _transition_duration])


func _update_transition(delta: float) -> void:
	_transition_progress += delta / _transition_duration
	if _transition_progress >= 1.0:
		_finish_transition()
		return

	global_position = _transition_start.lerp(_transition_target, _transition_progress)


func freeze() -> void:
	_frozen = true


func _finish_transition() -> void:
	_transitioning             = false
	_transition_progress       = 0.0
	position_smoothing_enabled = true
	position_smoothing_speed   = player_smoothing_speed

	if _player != null:
		global_position = _player.global_position
		_tracked_y      = _player.global_position.y

	if show_debug_logs:
		print("[Camera] state: transition complete, FOLLOW_PLAYER active")
