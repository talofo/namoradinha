extends Node2D

@export var player_scene: PackedScene
@export var spawn_position: Vector2 = Vector2(-4500, 100)

# Launch parameters
@export var launch_power: float = 0.8  # Current power (0.0 to 1.0)
@export var launch_strength: float = 1500.0  # Base magnitude of the launch force
@export var launch_angle_degrees: float = 45.0  # Current angle in degrees (0-90)

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
	
	# Launch with current angle and power
	launch_player(launch_angle_degrees, launch_power)

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
	
	print("Launching at angle:", angle_degrees, "degrees, power:", power)
	print("Launch vector:", launch_vector)
	
	# Apply launch to player
	if player_instance.has_method("launch"):
		player_instance.launch(launch_vector)

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
