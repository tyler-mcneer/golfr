extends Node

const HoleData = preload("res://resources/hole_data/hole_data.gd")

enum Mode { STROKE_PLAY, TIME_TRIAL }
enum Medal { NONE, BRONZE, SILVER, GOLD, SECRET }

# Session state (resets each hole)
var current_mode: Mode = Mode.STROKE_PLAY
var current_hole_id: String = ""
var current_strokes: int = 0
var current_hole_data: HoleData = null

# Timer state (driven by _process, no Timer node)
var current_time: float = 0.0
var _timer_running: bool = false

# Persistent records keyed by hole_id:
# {
#   "best_strokes": int,
#   "best_time": float,
#   "stroke_medal": Medal,
#   "time_medal": Medal
# }
var records: Dictionary = {}

# Adventure mode stub
var adventure_sequence_index: int = 0
var completed_holes: Array = []

const SAVE_PATH = "user://save.json"


func _ready() -> void:
	load_data()


func _process(delta: float) -> void:
	if _timer_running:
		current_time += delta


func start_hole(hole_id: String, mode: Mode, hole_data: HoleData) -> void:
	current_mode = mode
	current_hole_id = hole_id
	current_hole_data = hole_data
	current_strokes = 0
	current_time = 0.0
	_timer_running = mode == Mode.TIME_TRIAL

	if not records.has(hole_id):
		records[hole_id] = {
			"best_strokes": -1,
			"best_time": -1.0,
			"stroke_medal": Medal.NONE,
			"time_medal": Medal.NONE
		}


func add_stroke() -> void:
	current_strokes += 1


func stop_timer() -> void:
	_timer_running = false


func complete_hole() -> void:
	stop_timer()

	var stroke_medal := _calculate_medal(
		current_strokes,
		current_hole_data.stroke_bronze,
		current_hole_data.stroke_silver,
		current_hole_data.stroke_gold,
		current_hole_data.stroke_secret
	)

	var time_medal := _calculate_medal(
		current_time,
		current_hole_data.time_bronze,
		current_hole_data.time_silver,
		current_hole_data.time_gold,
		current_hole_data.time_secret
	)

	var rec: Dictionary = records[current_hole_id]

	# Update best strokes (lower is better; -1 means no record yet)
	if rec["best_strokes"] == -1 or current_strokes < rec["best_strokes"]:
		rec["best_strokes"] = current_strokes

	# Update best time (lower is better; -1.0 means no record yet)
	if rec["best_time"] < 0.0 or current_time < rec["best_time"]:
		rec["best_time"] = current_time

	# Update medals — only upgrade, never downgrade
	if stroke_medal > rec["stroke_medal"]:
		rec["stroke_medal"] = stroke_medal

	if time_medal > rec["time_medal"]:
		rec["time_medal"] = time_medal

	save()


func get_stroke_medal(hole_id: String) -> Medal:
	if records.has(hole_id):
		return records[hole_id]["stroke_medal"]
	return Medal.NONE


func get_time_medal(hole_id: String) -> Medal:
	if records.has(hole_id):
		return records[hole_id]["time_medal"]
	return Medal.NONE


func get_best_strokes(hole_id: String) -> int:
	if records.has(hole_id):
		return records[hole_id]["best_strokes"]
	return -1


func get_best_time(hole_id: String) -> float:
	if records.has(hole_id):
		return records[hole_id]["best_time"]
	return -1.0


# Compares score against thresholds; lower_is_better = true for strokes and time.
# Returns the highest medal tier achieved, or NONE if below bronze.
func _calculate_medal(score, bronze, silver, gold, secret, lower_is_better: bool = true) -> Medal:
	if lower_is_better:
		if score <= secret:
			return Medal.SECRET
		elif score <= gold:
			return Medal.GOLD
		elif score <= silver:
			return Medal.SILVER
		elif score <= bronze:
			return Medal.BRONZE
	else:
		if score >= secret:
			return Medal.SECRET
		elif score >= gold:
			return Medal.GOLD
		elif score >= silver:
			return Medal.SILVER
		elif score >= bronze:
			return Medal.BRONZE
	return Medal.NONE


func save() -> void:
	var data := {
		"records": {},
		"adventure_sequence_index": adventure_sequence_index,
		"completed_holes": completed_holes
	}

	# Store Medal enum values as ints so JSON round-trips cleanly
	for hole_id in records:
		var rec: Dictionary = records[hole_id]
		data["records"][hole_id] = {
			"best_strokes": rec["best_strokes"],
			"best_time": rec["best_time"],
			"stroke_medal": rec["stroke_medal"] as int,
			"time_medal": rec["time_medal"] as int
		}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
	else:
		push_error("GameState: failed to open save file for writing: %s" % SAVE_PATH)


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("GameState: failed to open save file for reading: %s" % SAVE_PATH)
		return

	var raw := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw)
	if parsed == null:
		push_error("GameState: save file contains invalid JSON")
		return

	adventure_sequence_index = int(parsed.get("adventure_sequence_index", 0))
	completed_holes = parsed.get("completed_holes", [])

	var saved_records = parsed.get("records", {})
	for hole_id in saved_records:
		var rec = saved_records[hole_id]
		records[hole_id] = {
			"best_strokes": int(rec.get("best_strokes", -1)),
			"best_time": float(rec.get("best_time", -1.0)),
			"stroke_medal": rec.get("stroke_medal", Medal.NONE) as Medal,
			"time_medal": rec.get("time_medal", Medal.NONE) as Medal
		}
