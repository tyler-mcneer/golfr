extends Node2D

signal hole_completed

@onready var hole_area: Area2D = $Hole/HoleArea
@onready var green_area: Area2D = $GreenArea

func _ready() -> void:
	hole_area.body_entered.connect(_on_hole_area_body_entered)
	green_area.body_entered.connect(_on_green_area_body_entered)
	green_area.body_exited.connect(_on_green_area_body_exited)

func _on_hole_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("golf_ball"):
		if body.has_method("enter_hole"):
			body.enter_hole()
		hole_completed.emit()

func _on_green_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("golf_ball") and body.has_method("enter_green"):
		body.enter_green()

func _on_green_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("golf_ball") and body.has_method("exit_green"):
		body.exit_green()
