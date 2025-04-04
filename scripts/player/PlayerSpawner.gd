extends Node2D

@export var player_scene: PackedScene
@export var player_character_scene: PackedScene = preload("res://player/PlayerCharacter.tscn")
@export var spawn_position: Vector2 = Vector2(-4500, 520) # Positioned just above the ground at y=540

# Launch parameters
@export var launch_power: float = 1  # Current power (0.0 to 1.0)
@export var launch_strength: float = 50000000.0  # Base magnitude of the launch force
@export var launch_angle_degrees: float = 45.0  # Current angle in degrees (0-90)

var player_instance: Node = null

func spawn_player():
	if player_instance:
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
	
	# Wait for the player to be properly positioned on the ground before launching
	# This ensures the player starts from the ground
	call_deferred("_check_and_launch_player")

func launch_player(angle_degrees: float, power: float):
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
	var launch_vector = direction * launch_magnitude
	
	# Debug output for launch parameters
	print("PlayerSpawner: Launch parameters - angle=", angle_degrees, " power=", power)
	print("PlayerSpawner: Launch magnitude=", launch_magnitude, " vector=", launch_vector)
	
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

func set_launch_power(power_percentage: float):
	launch_power = clamp(power_percentage, 0.1, 1.0)  # 10% to 100% power

# Method to get trajectory preview points for UI
func get_preview_trajectory() -> Array:
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
