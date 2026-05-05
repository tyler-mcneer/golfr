class_name HoleData
extends Resource

@export var hole_id: String = ""

# Stroke Play thresholds (lower is better)
@export var stroke_bronze: int = 6
@export var stroke_silver: int = 4
@export var stroke_gold: int = 3
@export var stroke_secret: int = 2

# Time Trial thresholds in seconds (lower is better)
@export var time_bronze: float = 60.0
@export var time_silver: float = 45.0
@export var time_gold: float = 30.0
@export var time_secret: float = 20.0
