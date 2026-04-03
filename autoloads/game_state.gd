extends Node

# Session data (resets each hole)
var current_mode: String = ""
var current_hole_id: String = ""
var current_strokes: int = 0
var current_time: float = 0.0
var ball_position: Vector2 = Vector2.ZERO
var respawn_active: bool = false

# Persistent data (saved to disk)
var hole_records: Dictionary = {}
var adventure_state: Dictionary = {
	"unlocked": false,
	"sequence_index": 0,
	"holes_completed": [],
	"transitions_completed": [],
	"story_flags": {}
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
