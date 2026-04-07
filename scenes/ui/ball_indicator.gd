extends Control

# Only shown when ball is RESTING (4) and off-screen.
# Arrow polygon is a child Polygon2D; this script drives its position and rotation.

const BALL_STATE_RESTING := 4
const BALL_STATE_AIMING  := 1

@export var arrow_screen_margin: float = 24.0
@export var vertical_deadzone: float = 0.3
@export var max_arrow_angle: float = PI / 4

var _ball: Node2D  = null
var _ball_state: int = -1

@onready var _arrow: Polygon2D = $ArrowPolygon


func _ready() -> void:
	_ball = get_tree().get_first_node_in_group("golf_ball")
	if _ball:
		_ball.ball_state_changed.connect(_on_ball_state_changed)
	_arrow.visible = false


func _on_ball_state_changed(new_state: int) -> void:
	_ball_state = new_state
	# Hide immediately on AIMING so arrow doesn't linger between shots.
	if new_state == BALL_STATE_AIMING:
		_arrow.visible = false


func _process(_delta: float) -> void:
	if _ball == null or _ball_state != BALL_STATE_RESTING:
		_arrow.visible = false
		return

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		_arrow.visible = false
		return

	# Convert ball world position to viewport pixel coordinates.
	# get_screen_center_position() + zoom avoids CanvasLayer transform interference.
	var viewport_rect := get_viewport_rect()
	var cam_center: Vector2 = cam.get_screen_center_position()
	var world_offset := _ball.global_position - cam_center
	var screen_pos: Vector2 = viewport_rect.size / 2.0 + Vector2(world_offset.x * cam.zoom.x, world_offset.y * cam.zoom.y)

	# Ball is on-screen — no arrow needed.
	if viewport_rect.has_point(screen_pos):
		_arrow.visible = false
		return

	_arrow.visible = true

	var center   := viewport_rect.size / 2.0
	var margin   := arrow_screen_margin
	var extent_x := (viewport_rect.size.x / 2.0) - margin
	var extent_y := (viewport_rect.size.y / 2.0) - margin

	var dx: float = screen_pos.x - center.x
	var dy: float = screen_pos.y - center.y

	# Normalise each axis independently so both range -1..1.
	var norm_x := clampf(dx / extent_x, -1.0, 1.0)
	var norm_y := clampf(dy / extent_y, -1.0, 1.0)

	# Clamp to the correct edge based on dominant axis.
	var edge_x: float
	var edge_y: float
	if absf(norm_x) >= absf(norm_y):
		edge_x = signf(dx) * extent_x + center.x
		edge_y = center.y + norm_y * extent_y
	else:
		edge_x = center.x + norm_x * extent_x
		edge_y = signf(dy) * extent_y + center.y

	_arrow.position = Vector2(edge_x, edge_y)

	# Apply dead zone then scale vertical influence; clamp via tan to enforce max_arrow_angle.
	var norm_y_adjusted: float = 0.0
	if absf(norm_y) > vertical_deadzone:
		norm_y_adjusted = signf(norm_y) * (absf(norm_y) - vertical_deadzone) / (1.0 - vertical_deadzone)

	# ArrowPolygon points right at rotation=0, so no offset needed.
	var angle_vector := Vector2(
		norm_x,
		clampf(norm_y_adjusted, -tan(max_arrow_angle), tan(max_arrow_angle))
	)
	_arrow.rotation = angle_vector.angle()
