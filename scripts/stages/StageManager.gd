extends Node2D

var current_stage: Node = null

func load_stage(stage_number: int) -> void:
	if current_stage:
		current_stage.queue_free()

	var stage_path := "res://stages/stage%d/Stage%d.tscn" % [stage_number, stage_number]
	var stage_resource = load(stage_path)

	if not stage_resource:
		push_error("Could not load stage: %s" % stage_path)
		return

	current_stage = stage_resource.instantiate()
	add_child(current_stage)
