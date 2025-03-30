extends Node2D

@export var player_scene: PackedScene
@export var spawn_position: Vector2 = Vector2(-4500, 100)
@export var launch_power: float = 0.8
@export var launch_strength_x: float = 1200.0
@export var launch_strength_y: float = 1400.0

var player_instance: Node = null

func spawn_player():
	if player_instance:
		player_instance.queue_free()

	if not player_scene:
		push_error("No player scene assigned.")
		return

	player_instance = player_scene.instantiate()
	player_instance.position = spawn_position
	add_child(player_instance)

	var launch_vector = Vector2(
		launch_strength_x * launch_power,
		-launch_strength_y * launch_power
	)

	if player_instance.has_method("launch"):
		player_instance.launch(launch_vector)
