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
	if stage_number == -1:
		return

	var scene_path := "res://environment/ground/stage%d/GroundTile_Stage%d.tscn" % [stage_number, stage_number]
	var ground_scene := load(scene_path) as PackedScene

	if not ground_scene:
		return

	var tile = ground_scene.instantiate()
	add_child(tile)

	# TEMPORARY: Place ground near screen center for visibility
	tile.position = Vector2(0, 540)  # This makes it visible regardless of camera setup
	# TODO: Replace with proper bottom alignment after CameraManager is in

	await get_tree().process_frame
	
	# Collect position data for visuals
	var ground_data = []
	for child in get_children():
		if child is StaticBody2D:
			var collision_shape = child.get_node_or_null("CollisionShape2D")
			if collision_shape and collision_shape.shape:
				var data = {
					"position": child.position,
					"size": collision_shape.shape.extents * 2  # Adjust based on your collision shape
				}
				ground_data.append(data)
	
	# Emit signal with position data for the EnvironmentSystem
	ground_tiles_created.emit(ground_data)
