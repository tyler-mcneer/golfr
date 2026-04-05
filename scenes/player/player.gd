extends CharacterBody2D

# --- Movement ---
@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var ground_acceleration: float = 1800.0
@export var ground_deceleration: float = 800.0
@export var air_acceleration: float = 600.0
@export var air_deceleration: float = 200.0

# --- Dash ---
@export var dash_initial_speed: float = 900.0
@export var dash_deceleration: float = 4000.0
@export var dash_min_speed: float = 200.0  # dash ends when we slow to this
@export var dash_gravity: bool = false

# --- Wall Jump ---
@export var wall_jump_velocity_x: float = 250.0
@export var wall_jump_velocity_y: float = -350.0
@export var wall_jump_lock_time: float = 0.15

# --- Coyote Time and Jump Buffer ---
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

# --- Internal State ---
var dash_available: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var wall_jump_timer: float = 0.0
var dash_direction: float = 1.0  # 1 for right, -1 for left
var movement_locked: bool = false
var is_invincible: bool = false

# --- Animation State ---
enum AnimationState { IDLE, RUN, JUMP, FALL, WALL_SLIDE, DASH }
var current_animation: AnimationState = AnimationState.IDLE

# --- Node References ---
# Assigns nodes after scene is loaded fully
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_left: RayCast2D = $WallRaycasts/wall_left
@onready var wall_right: RayCast2D = $WallRaycasts/wall_right
@onready var dash_indicator: Polygon2D = $DashIndicator

func _ready() -> void:
	var balls := get_tree().get_nodes_in_group("golf_ball")
	if balls.size() > 0:
		balls[0].player_lock.connect(_on_player_lock)

func _on_player_lock(locked: bool) -> void:
	movement_locked = locked
	is_invincible = locked
	if locked:
		velocity.x = 0.0

func _physics_process(delta: float) -> void:
	#_handle_dash_timer(delta)
	_apply_gravity(delta)
	_handle_coyote_timer(delta)
	if not movement_locked:
		_handle_jump_buffer(delta)
		_handle_jump()
		_handle_wall_jump()
		_handle_dash()
		_handle_horizontal_movement(delta)
	_refresh_dash_on_landing()
	_update_animation()
	move_and_slide()

# --- Dash Timer ---
# Counts down while dashing and stops the dash when complete
#func _handle_dash_timer(delta: float) -> void:
	#if is_dashing:
		#dash_timer -= delta

# --- Gravity ---
# Skipped entirely while dashing so dash travels in a straight line
func _apply_gravity(delta: float) -> void:
	if is_dashing and not dash_gravity:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

# --- Coyote Timer ---
# Gives the player a small window to jump after walking off a ledge
# Starts counting down the moment the player leaves the floor
func _handle_coyote_timer(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

# --- Jump Buffer ---
# If the player presses jump just before landing, register it
# so the jump fires the moment they touch the floor
func _handle_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

# --- Jump ---
# Fires if jump buffer is active and coyote timer is still valid
# Coyote timer covers both being on the floor and the brief window after leaving it
func _handle_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

# --- Wall Jump ---
# Jumps away from the wall horizontally, not straight up
# Only triggers when airborne and pressing into a wall
func _handle_wall_jump() -> void:
	if is_on_floor():
		return
	if Input.is_action_just_pressed("jump"):
		if wall_left.is_colliding():
			velocity.x = wall_jump_velocity_x
			velocity.y = wall_jump_velocity_y
			wall_jump_timer = wall_jump_lock_time
		elif wall_right.is_colliding():
			velocity.x = -wall_jump_velocity_x
			velocity.y = wall_jump_velocity_y
			wall_jump_timer = wall_jump_lock_time

# --- Dash ---
# Horizontal only, uses last facing direction
# Only available when dash_available is true
# Skipped if already dashing
func _handle_dash() -> void:
	if is_dashing:
		return
	if Input.is_action_just_pressed("dash") and dash_available:
		is_dashing = true
		dash_available = false
		velocity.x = dash_direction * dash_initial_speed
		velocity.y = 0.0 if not dash_gravity else velocity.y
		_update_dash_indicator()

# --- Horizontal Movement ---
# Skipped while dashing so dash speed is not overridden
# Uses different deceleration for grounded vs airborne
func _handle_horizontal_movement(delta: float) -> void:
	if is_dashing:
		# Decelerate the dash, end it when we drop below minimum speed
		velocity.x = move_toward(velocity.x, 0.0, dash_deceleration * delta)
		if abs(velocity.x) <= dash_min_speed:
			is_dashing = false
		return

	if wall_jump_timer > 0.0:
		wall_jump_timer -= delta
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		dash_direction = direction
		var accel = ground_acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
	else:
		var decel = ground_deceleration if is_on_floor() else air_deceleration
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

# --- Dash Refresh ---
# Dash becomes available again when the player lands
func _refresh_dash_on_landing() -> void:
	if is_on_floor():
		wall_jump_timer = 0.0
		if not dash_available:
			dash_available = true
			_update_dash_indicator()

# --- Dash Indicator ---
# Green when available, red when used
func _update_dash_indicator() -> void:
	dash_indicator.color = Color.GREEN if dash_available else Color.RED

# --- Animation ---
# Determines the correct state and updates the sprite
func _update_animation() -> void:
	var new_state: AnimationState

	if is_dashing:
		new_state = AnimationState.DASH
	elif not is_on_floor() and (wall_left.is_colliding() or wall_right.is_colliding()):
		new_state = AnimationState.WALL_SLIDE
	elif not is_on_floor() and velocity.y < 0:
		new_state = AnimationState.JUMP
	elif not is_on_floor() and velocity.y > 0:
		new_state = AnimationState.FALL
	elif abs(velocity.x) > 0.1:
		new_state = AnimationState.RUN
	else:
		new_state = AnimationState.IDLE

	# Handle sprite flipping based on facing direction
	if dash_direction < 0:
		animated_sprite.scale.x = 1.0
	else:
		animated_sprite.scale.x = -1.0

	# Only update if state changed to avoid restarting animations mid-cycle
	if new_state == current_animation:
		return
	current_animation = new_state

	match current_animation:
		AnimationState.IDLE:
			animated_sprite.stop()
			animated_sprite.frame = 0
		AnimationState.RUN:
			animated_sprite.play()
		AnimationState.JUMP:
			animated_sprite.stop()
			animated_sprite.frame = 1
		AnimationState.FALL:
			animated_sprite.stop()
			animated_sprite.frame = 1
		AnimationState.WALL_SLIDE:
			animated_sprite.stop()
			animated_sprite.frame = 0
		AnimationState.DASH:
			animated_sprite.stop()
			animated_sprite.frame = 1
