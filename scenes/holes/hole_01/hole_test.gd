extends Node2D

@export var completion_delay: float = 0.8

var stroke_count: int = 0
var _player: CharacterBody2D = null

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var ball_spawn: Marker2D = $BallSpawn
@onready var green: Node2D = $Green
@onready var hole_complete_ui: CanvasLayer = $HoleCompleteUI
@onready var stroke_label: Label = $HoleCompleteUI/Panel/VBoxContainer/StrokeLabel
@onready var restart_button: Button = $HoleCompleteUI/Panel/VBoxContainer/RestartButton

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.global_position = player_spawn.global_position

	var ball := get_tree().get_first_node_in_group("golf_ball")
	if ball:
		ball.global_position = ball_spawn.global_position
		ball.stroke_taken.connect(_on_stroke_taken)

	green.hole_completed.connect(_on_hole_completed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	hole_complete_ui.visible = false

func _on_stroke_taken() -> void:
	stroke_count += 1

func _on_hole_completed() -> void:
	if _player:
		_player.movement_locked = true
	var cam := get_tree().get_first_node_in_group("game_camera")
	if cam:
		cam.freeze()
	var timer := get_tree().create_timer(completion_delay)
	timer.timeout.connect(func() -> void:
		hole_complete_ui.visible = true
		stroke_label.text = "Strokes: " + str(stroke_count)
	)

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
