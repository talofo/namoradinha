extends Node2D

@export var player_scene: PackedScene
@export var player_character_scene: PackedScene = preload("res://player/PlayerCharacter.tscn")
@export var spawn_position: Vector2 = Vector2(-4500, 520) # Positioned just above the ground at y=540

# Launch parameters (stored for UI and initial setup only)
@export var launch_angle_degrees: float = 45.0  # Current angle in degrees (0-90)
@export var launch_power: float = 1.0  # Current power (0.0 to 1.0)

var player_instance: Node = null
var launch_system = null  # Reference to the LaunchSystem

func _exit_tree():
	# Clean up when the PlayerSpawner is removed from the scene
	if player_instance and launch_system:
		var entity_id = player_instance.get_instance_id()
		launch_system.unregister_entity(entity_id)

func _ready():
	# Get the LaunchSystem reference
	_get_launch_system()

# Get a reference to the LaunchSystem
func _get_launch_system() -> void:
	var motion_system = get_node_or_null("/root/Game/MotionSystem")
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
		# Fallback to original player scene if needed
		scene_to_use = player_scene
		if not scene_to_use:
			push_error("No player scene assigned.")
			return
	
	# Spawn player instance
	player_instance = scene_to_use.instantiate()
	player_instance.position = spawn_position
	add_child(player_instance)
	
	# Emit the global signal for player spawned
	GlobalSignals.player_spawned.emit(player_instance)
	
	# Make sure we have the LaunchSystem
	if not launch_system:
		_get_launch_system()
	
	# Register player with LaunchSystem
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		launch_system.register_entity(entity_id)
		
		# Set initial launch parameters
		launch_system.set_launch_parameters(entity_id, launch_angle_degrees, launch_power)
		
		# Wait for the player to be properly positioned before launching
		call_deferred("_prepare_and_launch_player")
	else:
		push_warning("PlayerSpawner: Could not register player with LaunchSystem - system not available")

# Prepare the player for launch by ensuring it's on the ground
func _prepare_and_launch_player():
	# Wait one frame to ensure the player is properly added to the scene
	await get_tree().process_frame
	
	# Check if player is on the ground
	if player_instance and player_instance.has_method("is_on_floor"):
		# Adjust player position to be just above the ground if needed
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(player_instance.global_position, 
					player_instance.global_position + Vector2(0, 1000))
		var result = space_state.intersect_ray(query)
		
		if result and result.has("position"):
			# Adjust player position to be just above the detected ground
			player_instance.position.y = result.position.y - 10 # 10 pixels above ground
		
		# Wait a few frames for physics to settle
		var max_wait_frames = 10
		var frames_waited = 0
		
		while not player_instance.is_on_floor() and frames_waited < max_wait_frames:
			await get_tree().process_frame
			frames_waited += 1
			
			# Apply small downward velocity to ensure player moves toward ground
			if player_instance is CharacterBody2D and not player_instance.is_on_floor():
				player_instance.velocity.y = min(player_instance.velocity.y + 10, 100)
				player_instance.move_and_slide()
	
	# Launch the player using LaunchSystem
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		
		# Launch the entity, passing its current position, and get the launch vector
		var launch_vector = launch_system.launch_entity(entity_id, player_instance.position)
		
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
