extends Control

func _ready() -> void:
	$Layout/Buttons/StrokePlayButton.pressed.connect(_on_stroke_play_pressed)
	$Layout/Buttons/TimeTrialButton.pressed.connect(_on_time_trial_pressed)

func _on_stroke_play_pressed() -> void:
	GameState.current_mode = GameState.Mode.STROKE_PLAY
	get_tree().change_scene_to_file("res://scenes/holes/hole_01/hole_test.tscn")

func _on_time_trial_pressed() -> void:
	GameState.current_mode = GameState.Mode.TIME_TRIAL
	get_tree().change_scene_to_file("res://scenes/holes/hole_01/hole_test.tscn")
