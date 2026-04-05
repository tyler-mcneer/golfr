extends CanvasLayer

var _ball: Node
var _ball_state: int = -1
var _stroke_count: int = 0

@onready var power_bar: Control = $Control/PowerBar
@onready var background_rect: ColorRect = $Control/PowerBar/BackgroundRect
@onready var fill_rect: ColorRect = $Control/PowerBar/FillRect
@onready var stroke_label: Label = $Control/StrokeLabel

func _ready() -> void:
	power_bar.hide()
	_ball = get_tree().get_first_node_in_group("golf_ball")
	if _ball:
		_ball.ball_state_changed.connect(_on_ball_state_changed)
		_ball.stroke_taken.connect(_on_stroke_taken)

func _process(_delta: float) -> void:
	if _ball and _ball_state == _ball.State.POWER:
		fill_rect.size.x = background_rect.size.x * _ball.current_power

func _on_ball_state_changed(new_state: int) -> void:
	_ball_state = new_state
	if new_state == _ball.State.AIMING:
		fill_rect.size.x = 0.0
		power_bar.show()
	elif new_state == _ball.State.RESTING:
		power_bar.hide()

func _on_stroke_taken() -> void:
	_stroke_count += 1
	stroke_label.text = "Strokes: %d" % _stroke_count
