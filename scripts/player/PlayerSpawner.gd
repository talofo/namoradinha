extends Node2D

@export var player_scene: PackedScene
@export var spawn_position: Vector2 = Vector2(-900, -75)

var player_instance: Node = null

func spawn_player():
	if player_instance:
		player_instance.queue_free()

	if not player_scene:
		push_error("No player scene assigned to PlayerSpawner.")
		return

	player_instance = player_scene.instantiate()
	player_instance.position = spawn_position
	add_child(player_instance)

	# Immediately launch it downward with an initial velocity
	if player_instance.has_method("launch"):
		player_instance.launch(Vector2(300, -1000))  # Adjust power as needed
