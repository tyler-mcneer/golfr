extends RigidBody2D

signal player_lock(locked: bool)
signal ball_state_changed(new_state: int)
signal stroke_taken

# ── State Machine ────────────────────────────────────────────
enum State { IDLE, AIMING, POWER, IN_FLIGHT, RESTING }
var state: State = State.IN_FLIGHT

# ── Exported Tuning Values ───────────────────────────────────
@export var aim_rotation_speed: float = 2.5        # radians per second
@export var max_power: float = 800.0               # max launch speed (pixels/sec)
@export var power_bar_fill_speed: float = 1.0      # full bar fill in 1 second
@export var ball_bounciness: float = 0.35          # physics material bounce
@export var ball_friction: float = 0.6             # physics material friction
@export var linear_damp_value: float = 1.5         # overall roll distance
@export var angular_damp_value: float = 2.0        # spin resistance after landing
@export var rest_speed_threshold: float = 8.0      # speed below which ball is "resting"
@export var rest_time_required: float = 0.4        # seconds below threshold before RESTING

# Putter overrides (applied automatically on green)
@export var putter_max_power: float = 250.0

# ── Internal State ───────────────────────────────────────────
var aim_angle: float = -PI / 2.0                   # starts pointing straight up
var power: float = 0.0                             # 0.0 to 1.0
var current_power: float:
	get:
		return power
var is_on_green: bool = false
var _power_direction: float = 1.0
var _rest_timer: float = 0.0
var _respawn_marker_position: Vector2 = Vector2.ZERO
var _launch_impulse: Vector2 = Vector2.ZERO

# ── Node References ──────────────────────────────────────────
@onready var aim_arrow: Node2D = $AimArrow
@onready var arrow_line: Line2D = $AimArrow/ArrowLine
@onready var player_detector: Area2D = $PlayerDetector

func _ready() -> void:
	_update_physics_material()
	linear_damp = linear_damp_value
	angular_damp = angular_damp_value
	_set_aim_arrow_visible(false)
	player_detector.body_entered.connect(_on_player_detector_body_entered)

# ── Main Loop ────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			pass
		State.AIMING:
			_handle_aiming(delta)
		State.POWER:
			_handle_power(delta)
		State.IN_FLIGHT:
			_handle_in_flight(delta)
		State.RESTING:
			pass

# ── Player Detection ─────────────────────────────────────────
func _on_player_detector_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if state == State.IDLE or state == State.RESTING:
		_hide_respawn_marker()
		_enter_aiming()

# ── Input ────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):  # spacebar
		match state:
			State.AIMING:
				_enter_power()
			State.POWER:
				_fire_shot()

# ── State: AIMING ────────────────────────────────────────────
func _enter_aiming() -> void:
	state = State.AIMING
	if is_on_green:
		var holes := get_tree().get_nodes_in_group("golf_hole")
		if holes.size() > 0:
			aim_angle = 0.0 if holes[0].global_position.x >= global_position.x else -PI
	player_lock.emit(true)
	ball_state_changed.emit(State.AIMING)
	_set_aim_arrow_visible(true)
	_update_aim_arrow()

func _handle_aiming(delta: float) -> void:
	if is_on_green:
		# Putter: toggle between pointing right (0) and pointing left (-PI).
		if Input.is_action_just_pressed("ui_right"):
			aim_angle = 0.0
		elif Input.is_action_just_pressed("ui_left"):
			aim_angle = -PI
	else:
		var input := Input.get_axis("ui_left", "ui_right")
		aim_angle = clampf(aim_angle + input * aim_rotation_speed * delta, -PI, 0.0)
	_update_aim_arrow()

func _update_aim_arrow() -> void:
	aim_arrow.global_rotation = aim_angle

# ── State: POWER ─────────────────────────────────────────────
func _enter_power() -> void:
	state = State.POWER
	power = 0.0
	_power_direction = 1.0
	ball_state_changed.emit(State.POWER)

func _handle_power(delta: float) -> void:
	power += power_bar_fill_speed * delta * _power_direction
	if power >= 1.0:
		power = 1.0
		_power_direction = -1.0
	elif power <= 0.0:
		power = 0.0
		_power_direction = 1.0

func _fire_shot() -> void:
	var active_max_power := putter_max_power if is_on_green else max_power
	var direction := Vector2(cos(aim_angle), sin(aim_angle))
	_launch_impulse = direction * active_max_power * power

	# Record hit-from position for respawn marker
	_respawn_marker_position = global_position
	_update_respawn_marker()

	_set_aim_arrow_visible(false)
	linear_damp = 0.0
	state = State.IN_FLIGHT
	ball_state_changed.emit(State.IN_FLIGHT)
	stroke_taken.emit()

# ── State: IN_FLIGHT ─────────────────────────────────────────
func _handle_in_flight(_delta: float) -> void:
	if _launch_impulse != Vector2.ZERO:
		freeze = false
		linear_velocity = Vector2.ZERO
		apply_central_impulse(_launch_impulse)
		_launch_impulse = Vector2.ZERO
		return

	# Check if ball has come to rest
	if linear_velocity.length() < rest_speed_threshold:
		_rest_timer += _delta
		if _rest_timer >= rest_time_required:
			_enter_resting()
	else:
		_rest_timer = 0.0

func _enter_resting() -> void:
	state = State.RESTING
	linear_damp = linear_damp_value
	freeze = true
	linear_velocity = Vector2.ZERO
	player_lock.emit(false)
	ball_state_changed.emit(State.RESTING)

# ── Green Detection ──────────────────────────────────────────
func enter_green() -> void:
	is_on_green = true

func exit_green() -> void:
	is_on_green = false

# ── Respawn Marker ───────────────────────────────────────────
func _update_respawn_marker() -> void:
	var markers := get_tree().get_nodes_in_group("respawn_marker")
	if markers.size() > 0:
		markers[0].global_position = _respawn_marker_position
		markers[0].visible = true

func _hide_respawn_marker() -> void:
	var markers := get_tree().get_nodes_in_group("respawn_marker")
	if markers.size() > 0:
		markers[0].visible = false

# ── Physics Material ─────────────────────────────────────────
func _update_physics_material() -> void:
	var mat := PhysicsMaterial.new()
	mat.bounce = ball_bounciness
	mat.friction = ball_friction
	physics_material_override = mat
	
func _set_aim_arrow_visible(enabled: bool) -> void:
	aim_arrow.visible = enabled
