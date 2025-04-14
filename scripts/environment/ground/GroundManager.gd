extends Node2D

signal ground_tiles_created(data)

# The stage number this ground manager belongs to. Will be set by StageManager.
var stage_number: int = -1 
@export var ground_height: float = 100.0  # Match your CollisionShape height

# Called by StageManager after this node is added to the scene tree.
func set_stage_number(num: int):
	stage_number = num
	# Optional: Add a check in _ready if logic depends on stage_number being set immediately.
	# However, StageManager should call this before _ready executes its main logic.
	# Load the ground tile now that the stage number is known
	_load_ground_tile()

func _ready():
	# _ready might be called before set_stage_number, so we defer loading
	pass

# Loads and positions the ground tile based on the set stage_number
func _load_ground_tile():
	# DISABLED: Ground creation is now handled by the chunk system
	# This prevents duplicate ground elements with collision shapes
	
	if stage_number == -1:
		return
	
	# Instead of creating a new ground tile, we'll just emit an empty ground_data array
	# This ensures compatibility with systems expecting the signal
	var ground_data = []
	ground_tiles_created.emit(ground_data)
	
	# Log for debugging
	print("GroundManager: Ground creation skipped - now handled by chunk system")
