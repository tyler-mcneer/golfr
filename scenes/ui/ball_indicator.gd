extends Control

# Only shown when ball is RESTING (4) and off-screen.
# Arrow polygon is a child Polygon2D; this script drives its position and rotation.

const BALL_STATE_RESTING := 4
const BALL_STATE_AIMING  := 1

@export var arrow_screen_margin: float = 24.0

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

	var viewport_size := get_viewport_rect().size

	# Convert ball world position to screen coordinates.
	# cam.to_local() gives position relative to camera centre (0,0 = centre).
	var cam_local  := cam.to_local(_ball.global_position)
	var screen_pos := cam_local + viewport_size * 0.5

	# Ball is on-screen — no arrow needed.
	if screen_pos.x >= 0.0 and screen_pos.x <= viewport_size.x \
	and screen_pos.y >= 0.0 and screen_pos.y <= viewport_size.y:
		_arrow.visible = false
		return

	_arrow.visible = true

	# Direction from screen centre toward ball screen position.
	var screen_center := viewport_size * 0.5
	var dir := (screen_pos - screen_center).normalized()

	# Project far along that direction then clamp to the margin inset rect.
	var margin    := arrow_screen_margin
	var arrow_pos := screen_center + dir * 10000.0
	arrow_pos.x   = clampf(arrow_pos.x, margin, viewport_size.x - margin)
	arrow_pos.y   = clampf(arrow_pos.y, margin, viewport_size.y - margin)

	_arrow.position = arrow_pos
	_arrow.rotation = dir.angle()
