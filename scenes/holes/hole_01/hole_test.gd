extends Node2D

@export var completion_delay: float = 0.8
@export var hole_data: HoleData

var _player: CharacterBody2D = null

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var ball_spawn: Marker2D = $BallSpawn
@onready var green: Node2D = $Green
@onready var hole_complete_ui: CanvasLayer = $HoleCompleteUI
@onready var stroke_label: Label = $HoleCompleteUI/Panel/VBoxContainer/StrokeLabel
@onready var best_label: Label = $HoleCompleteUI/Panel/VBoxContainer/BestLabel
@onready var restart_button: Button = $HoleCompleteUI/Panel/VBoxContainer/RestartButton
@onready var ball = get_tree().get_first_node_in_group("golf_ball")

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.global_position = player_spawn.global_position

	if ball:
		ball.global_position = ball_spawn.global_position
		ball.stroke_taken.connect(_on_stroke_taken)

	green.hole_completed.connect(_on_hole_completed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	hole_complete_ui.visible = false

	GameState.start_hole("hole_test", GameState.Mode.STROKE_PLAY, hole_data)
	ball.stroke_taken.connect(GameState.add_stroke)

func _on_stroke_taken() -> void:
	pass

func _on_hole_completed() -> void:
	if _player:
		_player.movement_locked = true
	var cam := get_tree().get_first_node_in_group("game_camera")
	if cam:
		cam.freeze()
	GameState.complete_hole()
	var timer := get_tree().create_timer(completion_delay)
	timer.timeout.connect(func() -> void:
		hole_complete_ui.visible = true
		stroke_label.text = "Strokes: " + str(GameState.current_strokes)
		var best := GameState.get_best_strokes("hole_test")
		var medal := GameState.get_stroke_medal("hole_test")
		var medal_str := ""
		match medal:
			GameState.Medal.SECRET:
				medal_str = " ⭐"
			GameState.Medal.GOLD:
				medal_str = " 🥇"
			GameState.Medal.SILVER:
				medal_str = " 🥈"
			GameState.Medal.BRONZE:
				medal_str = " 🥉"
		if best == -1:
			best_label.text = "Best: -"
		else:
			best_label.text = "Best: " + str(best) + medal_str
	)

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
