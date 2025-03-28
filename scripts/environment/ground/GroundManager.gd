extends Node2D

@onready var stage_number := StageUtils.get_stage_number_from_parent(self)
@export var ground_height: float = 100.0  # Match your CollisionShape height

func _ready():
	var scene_path := "res://environment/ground/stage%d/GroundTile_Stage%d.tscn" % [stage_number, stage_number]
	var ground_scene := load(scene_path) as PackedScene

	if not ground_scene:
		push_error("Could not load ground tile for stage %d at: %s" % [stage_number, scene_path])
		return

	var tile = ground_scene.instantiate()
	add_child(tile)

	# TEMPORARY: Place ground near screen center for visibility
	tile.position = Vector2(0, 540)  # This makes it visible regardless of camera setup
	# TODO: Replace with proper bottom alignment after CameraManager is in

	await get_tree().process_frame
	print("Tile global position:", tile.global_position)
	print("Tile Y:", tile.position.y)

	# Optional debug line (also visible)
	var debug_line = ColorRect.new()
	debug_line.color = Color.YELLOW
	debug_line.size = Vector2(1920, 2)
	debug_line.position = Vector2(0, tile.position.y + ground_height)
	add_child(debug_line)
