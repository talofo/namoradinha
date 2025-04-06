extends Node2D

var current_stage: Node = null

func load_stage(stage_number: int) -> void:
	if current_stage:
		current_stage.queue_free()

	var stage_path := "res://stages/stage%d/Stage%d.tscn" % [stage_number, stage_number]
	var stage_resource = load(stage_path)

	if not stage_resource:
		ErrorHandler.error("StageManager", "Could not load stage: %s" % stage_path)
		return

	current_stage = stage_resource.instantiate()
	add_child(current_stage)
	
	# Find the GroundManager within the loaded stage and set its number
	# Assuming the GroundManager node is named "GroundManager" within the stage scene
	var ground_manager = current_stage.find_child("GroundManager", true, false) 
	if ground_manager and ground_manager.has_method("set_stage_number"):
		ground_manager.set_stage_number(stage_number)
	else:
		ErrorHandler.warning("StageManager", "Could not find GroundManager node or set_stage_number method in stage %d" % stage_number)
