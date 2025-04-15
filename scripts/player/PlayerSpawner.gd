extends Node2D

@export var player_character_scene: PackedScene = load("res://player/PlayerCharacter.tscn")
@export var spawn_position: Vector2 = Vector2(-4500, -50) # Positioned just above the ground at y=0 but height of 50. (was, Y=540)

# Launch parameters (stored for UI and initial setup only)
@export var launch_angle_degrees: float = 45.0  # Current angle in degrees (0-90)
@export var launch_power: float = 1.0  # Current power (0.0 to 1.0)

var player_instance: Node = null
var motion_system = null  # Will be set via setter method
var launch_system = null  # Reference to the LaunchSystem

# Add setter method for motion system
func set_motion_system(system) -> void:
	motion_system = system
	# Update LaunchSystem reference
	_update_launch_system()
	# If we already have a player instance, update it too
	if player_instance and player_instance.has_method("set_motion_system"):
		player_instance.set_motion_system(motion_system)

func _exit_tree():
	# Clean up when the PlayerSpawner is removed from the scene
	if player_instance and launch_system:
		var entity_id = player_instance.get_instance_id()
		launch_system.unregister_entity(entity_id)

func _ready():
	# If motion_system is already set, update launch_system
	if motion_system:
		_update_launch_system()

# Get a reference to the LaunchSystem from the motion system
func _update_launch_system() -> void:
	if motion_system:
		launch_system = motion_system.get_subsystem("LaunchSystem")

func spawn_player():
	if player_instance:
		# Clean up previous player instance
		if launch_system:
			var entity_id = player_instance.get_instance_id()
			launch_system.unregister_entity(entity_id)
		
		player_instance.queue_free()
	
	# Use the PlayerCharacter scene
	var scene_to_use = player_character_scene

	if not scene_to_use:
		push_error("PlayerCharacter scene not assigned in PlayerSpawner.")
		return

	# Spawn player instance
	player_instance = scene_to_use.instantiate()
	player_instance.position = spawn_position
	
	# Set motion system reference before adding to scene tree
	if motion_system and player_instance.has_method("set_motion_system"):
		player_instance.set_motion_system(motion_system)
	
	add_child(player_instance)
	
	# Emit the global signal for player spawned
	GlobalSignals.player_spawned.emit(player_instance)
	
	# Make sure we have the LaunchSystem
	if not launch_system:
		_update_launch_system()
	
	# Register player with LaunchSystem
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		launch_system.register_entity(entity_id)
		
		# Set initial launch parameters
		print("[PlayerSpawner] Setting launch params - Angle: ", launch_angle_degrees, ", Power: ", launch_power) # DEBUG PRINT
		launch_system.set_launch_parameters(entity_id, launch_angle_degrees, launch_power)
		print("[PlayerSpawner] Launch params set for entity: ", entity_id) # DEBUG PRINT
		
		# Wait for the player to be properly positioned before launching
		call_deferred("_prepare_and_launch_player")
	else:
		push_warning("Could not register player with LaunchSystem in PlayerSpawner.")

# Prepare the player for launch by ensuring it's on the ground
# Prepare the player for launch (Simplified)
func _prepare_and_launch_player():
	# Wait one frame to ensure the player is properly added to the scene tree and physics state is available
	await get_tree().process_frame 
	
	# Launch the player using LaunchSystem
	# Rely on initial spawn position and normal physics process to handle ground placement.
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		
		# Launch the entity, passing its current position, and get the launch vector
		print("[PlayerSpawner] Calling launch_entity for entity: ", entity_id) # DEBUG PRINT
		var launch_vector = launch_system.launch_entity(entity_id, player_instance.position)
		print("[PlayerSpawner] Launch vector received: ", launch_vector) # DEBUG PRINT
		
		# Update player state
		player_instance.has_launched = true
		player_instance.is_sliding = false
		player_instance.velocity = launch_vector
		player_instance.floor_position_y = player_instance.position.y
		player_instance.max_height_y = player_instance.position.y

# Helper methods for UI integration
func set_launch_angle(degrees: float):
	launch_angle_degrees = clamp(degrees, 0, 90)
	
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		launch_system.set_launch_parameters(entity_id, launch_angle_degrees, launch_power)

func set_launch_power(power_percentage: float):
	launch_power = clamp(power_percentage, 0.1, 1.0)
	
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		launch_system.set_launch_parameters(entity_id, launch_angle_degrees, launch_power)

# Method to get trajectory preview points for UI
func get_preview_trajectory() -> Array:
	if not launch_system or not player_instance:
		return []
		
	var entity_id = player_instance.get_instance_id()
	return launch_system.get_preview_trajectory(entity_id)
