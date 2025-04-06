extends Node2D

# The stage number this ground manager belongs to. Will be set by StageManager.
var stage_number: int = -1 
@export var ground_height: float = 100.0  # Match your CollisionShape height

# Called by StageManager after this node is added to the scene tree.
func set_stage_number(num: int):
	stage_number = num
	# Optional: Add a check in _ready if logic depends on stage_number being set immediately.
	# However, StageManager should call this before _ready executes its main logic.
	ErrorHandler.info("GroundManager", "Stage number set to: %d" % stage_number)
	# Load the ground tile now that the stage number is known
	_load_ground_tile()

func _ready():
	# _ready might be called before set_stage_number, so we defer loading
	pass

# Loads and positions the ground tile based on the set stage_number
func _load_ground_tile():
	if stage_number == -1:
		ErrorHandler.error("GroundManager", "Attempted to load ground tile before stage number was set.")
		return
		
	var scene_path := "res://environment/ground/stage%d/GroundTile_Stage%d.tscn" % [stage_number, stage_number]
	var ground_scene := load(scene_path) as PackedScene

	if not ground_scene:
		ErrorHandler.error("GroundManager", "Could not load ground tile for stage %d at: %s" % [stage_number, scene_path])
		return

	var tile = ground_scene.instantiate()
	add_child(tile)

	# TEMPORARY: Place ground near screen center for visibility
	tile.position = Vector2(0, 540)  # This makes it visible regardless of camera setup
	# TODO: Replace with proper bottom alignment after CameraManager is in

	await get_tree().process_frame
	ErrorHandler.debug("GroundManager", "Tile global position: %s" % tile.global_position)
	ErrorHandler.debug("GroundManager", "Tile Y: %s" % tile.position.y)

	# Optional debug line (also visible)
	var debug_line = ColorRect.new()
	debug_line.color = Color.YELLOW
	debug_line.size = Vector2(1920, 2)
	debug_line.position = Vector2(0, tile.position.y + ground_height)
	add_child(debug_line)
