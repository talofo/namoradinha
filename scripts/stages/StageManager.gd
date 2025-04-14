extends Node2D

# StageConfig is available globally via class_name

var current_stage: Node = null

func load_stage(stage_number: int) -> void:
	if current_stage:
		current_stage.queue_free()

	var stage_path := "res://stages/stage%d/Stage%d.tscn" % [stage_number, stage_number]
	var stage_resource = load(stage_path)

	if not stage_resource:
		push_error("Failed to load stage resource: " + stage_path)
		return

	current_stage = stage_resource.instantiate()
	add_child(current_stage)

	# Stage is now loaded, no need to configure GroundManager as it's handled by the chunk system
	
	# Create stage config for environment system
	var config = StageConfig.new()
	config.stage_id = stage_number
	
	# Map stage_id to theme_id (customize as needed)
	match stage_number:
		1:
			config.theme_id = "default"
		_:
			config.theme_id = "default"
	
	# Emit signal that will be caught by EnvironmentSystem
	GlobalSignals.stage_loaded.emit(config)
