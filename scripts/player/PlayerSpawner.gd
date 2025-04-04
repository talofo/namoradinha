extends Node2D

@export var player_scene: PackedScene
@export var player_character_scene: PackedScene = preload("res://player/PlayerCharacter.tscn")
@export var spawn_position: Vector2 = Vector2(-4500, 520) # Positioned just above the ground at y=540

# Launch parameters
@export var launch_power: float = 1  # Current power (0.0 to 1.0)
@export var launch_strength: float = 1500.0  # Base magnitude of the launch force
@export var launch_angle_degrees: float = 45.0  # Current angle in degrees (0-90)

var player_instance: Node = null
var launch_system = null  # Reference to the LaunchSystem

func _exit_tree():
	# Clean up when the PlayerSpawner is removed from the scene
	if player_instance and launch_system:
		var entity_id = player_instance.get_instance_id()
		launch_system.unregister_entity(entity_id)
		print("PlayerSpawner: Player unregistered from LaunchSystem on exit")

func _ready():
	# Get reference to the LaunchSystem
	var motion_system = get_node_or_null("/root/Game/MotionSystem")
	if motion_system:
		launch_system = motion_system.get_subsystem("LaunchSystem")
		if launch_system:
			print("PlayerSpawner: LaunchSystem found")
		else:
			print("PlayerSpawner: LaunchSystem not found in MotionSystem")
	else:
		print("PlayerSpawner: MotionSystem not found")

#func _ready():
	# Force the launch_strength to our desired value, overriding any editor settings
	#launch_strength = 1500.0

func spawn_player():
	if player_instance:
		# Unregister player from LaunchSystem if available
		if launch_system:
			var entity_id = player_instance.get_instance_id()
			launch_system.unregister_entity(entity_id)
			print("PlayerSpawner: Player unregistered from LaunchSystem")
		
		player_instance.queue_free()
	
	print("PlayerSpawner: Spawning player at position ", spawn_position)
	
	# Use the new PlayerCharacter class that properly uses composition
	var scene_to_use = player_character_scene
	
	if not scene_to_use:
		# Fallback to original player scene if MotionSystemPlayer is not assigned
		scene_to_use = player_scene
		if not scene_to_use:
			push_error("No player scene assigned.")
			return
	
	# Spawn player instance
	player_instance = scene_to_use.instantiate()
	player_instance.position = spawn_position
	add_child(player_instance)
	
	print("PlayerSpawner: Player added to scene")
	
	# Register player with LaunchSystem if available
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		launch_system.register_entity(entity_id)
		
		# Set initial launch parameters
		launch_system.set_launch_parameters(
			entity_id, launch_angle_degrees, launch_power, launch_strength)
		print("PlayerSpawner: Player registered with LaunchSystem")
	
	# Wait for the player to be properly positioned on the ground before launching
	# This ensures the player starts from the ground
	call_deferred("_check_and_launch_player")

func launch_player(angle_degrees: float, power: float):
	var launch_vector: Vector2
	
	# Debug output for launch parameters
	print("PlayerSpawner: Launch parameters - angle=", angle_degrees, " power=", power)
	
	# Use LaunchSystem if available
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		
		# Register entity if not already registered
		launch_system.register_entity(entity_id)
		
		# Set launch parameters and launch
		launch_vector = launch_system.launch_entity_with_parameters(
			entity_id, angle_degrees, power, launch_strength)
			
		print("PlayerSpawner: Using LaunchSystem - vector=", launch_vector)
	else:
		# Fallback to original implementation if LaunchSystem not available
		# Convert angle to radians
		var angle_radians = deg_to_rad(angle_degrees)
		
		# Calculate direction vector based on angle
		# In Godot, 0 degrees is right, 90 is up, 180 is left, 270 is down
		var direction = Vector2(
			cos(angle_radians),  # X component
			-sin(angle_radians)  # Y component (negative since Y increases downward)
		)
		
		# Calculate final launch vector
		var launch_magnitude = launch_strength * power
		launch_vector = direction * launch_magnitude
		
		print("PlayerSpawner: Using original implementation - magnitude=", launch_magnitude, " vector=", launch_vector)
	
	# Apply launch to player
	if player_instance.has_method("launch"):
		player_instance.launch(launch_vector)

# Check if player is on ground and then launch
func _check_and_launch_player():
	# Wait one frame to ensure the player is properly added to the scene
	await get_tree().process_frame
	
	print("PlayerSpawner: Checking if player is on ground")
	
	# Check if player is on the ground
	if player_instance and player_instance.has_method("is_on_floor"):
		# Wait until player is on the floor
		var max_wait_frames = 20  # Increased maximum frames to wait
		var frames_waited = 0
		
		# Print ground position to debug
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(player_instance.global_position, 
					player_instance.global_position + Vector2(0, 1000))
		var result = space_state.intersect_ray(query)
		
		if result and result.has("position"):
			print("PlayerSpawner: Ground detected at: ", result.position)
			# Adjust player position to be just above the detected ground
			player_instance.position.y = result.position.y - 10 # 10 pixels above ground
			print("PlayerSpawner: Adjusted player position to: ", player_instance.position)
		
		while not player_instance.is_on_floor() and frames_waited < max_wait_frames:
			print("PlayerSpawner: Waiting for player to be on floor, frame ", frames_waited)
			await get_tree().process_frame
			frames_waited += 1
			
			# Apply small downward velocity to ensure player moves toward ground
			if player_instance is CharacterBody2D and not player_instance.is_on_floor():
				player_instance.velocity.y = min(player_instance.velocity.y + 10, 100) # Gradually increase, capped at 100
				player_instance.move_and_slide()
		
		if player_instance.is_on_floor():
			print("PlayerSpawner: Player is on floor, launching")
		else:
			print("PlayerSpawner: Max wait frames reached, launching anyway")
			# If we failed to get on floor, check current position
			print("PlayerSpawner: Current player position: ", player_instance.position)
		
		# Now launch the player
		launch_player(launch_angle_degrees, launch_power)
	else:
		# Fallback if player doesn't have is_on_floor method
		print("PlayerSpawner: Player doesn't have is_on_floor method, launching directly")
		launch_player(launch_angle_degrees, launch_power)

# Helper methods for UI integration
func set_launch_angle(degrees: float):
	launch_angle_degrees = clamp(degrees, 0, 90)  # Restrict to 0-90 degrees (forward only)
	
	# Update LaunchSystem if available
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		
		# Register entity if not already registered
		if not launch_system.get_launch_parameters(entity_id).size() > 0:
			launch_system.register_entity(entity_id)
		
		# Update launch angle
		launch_system.set_launch_parameters(
			entity_id, launch_angle_degrees, launch_power, launch_strength)

func set_launch_power(power_percentage: float):
	launch_power = clamp(power_percentage, 0.1, 1.0)  # 10% to 100% power
	
	# Update LaunchSystem if available
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		
		# Register entity if not already registered
		if not launch_system.get_launch_parameters(entity_id).size() > 0:
			launch_system.register_entity(entity_id)
		
		# Update launch power
		launch_system.set_launch_parameters(
			entity_id, launch_angle_degrees, launch_power, launch_strength)

# Method to get trajectory preview points for UI
func get_preview_trajectory() -> Array:
	# Use LaunchSystem if available
	if launch_system and player_instance:
		var entity_id = player_instance.get_instance_id()
		
		# Register entity if not already registered
		if not launch_system.get_launch_parameters(entity_id).size() > 0:
			launch_system.register_entity(entity_id)
		
		# Set current launch parameters
		launch_system.set_launch_parameters(
			entity_id, launch_angle_degrees, launch_power, launch_strength)
			
		print("PlayerSpawner: Using LaunchSystem for trajectory preview")
		return launch_system.get_preview_trajectory(entity_id)
	else:
		# Fallback to original implementation if LaunchSystem not available
		print("PlayerSpawner: Using original implementation for trajectory preview")
		var points = []
		var angle_radians = deg_to_rad(launch_angle_degrees)
		var initial_velocity = Vector2(
			cos(angle_radians) * launch_strength * launch_power,
			-sin(angle_radians) * launch_strength * launch_power
		)
		
		# Simple physics simulation to get trajectory points
		var pos = Vector2.ZERO
		var vel = initial_velocity
		var gravity = 1200  # Match the gravity in CharacterPlayer
		var time_step = 0.1
		var max_steps = 20
		
		for i in range(max_steps):
			points.append(pos)
			vel.y += gravity * time_step
			pos += vel * time_step
			
			# Stop if we hit the ground
			if pos.y > 0:
				points.append(Vector2(pos.x, 0))
				break
		
		return points
