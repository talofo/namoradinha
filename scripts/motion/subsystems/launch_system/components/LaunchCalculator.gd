class_name LaunchCalculator
extends RefCounted

# Reference to motion system for config access
var _motion_system = null

func set_motion_system(motion_system) -> void:
	_motion_system = motion_system

# Calculate launch vector based on entity data
# entity_data: Dictionary containing launch parameters
# Returns: The calculated launch vector
func calculate_launch_vector(entity_data: Dictionary) -> Vector2:
	print("[LaunchCalculator] Calculating vector with data: ", entity_data) # DEBUG PRINT
	if entity_data.is_empty():
		print("[LaunchCalculator] Entity data empty, returning ZERO.") # DEBUG PRINT
		return Vector2.ZERO

	# Convert angle to radians
	var angle_radians = deg_to_rad(entity_data.launch_angle_degrees)

	# Calculate direction vector based on angle
	# In Godot, 0 degrees is right, 90 is up, 180 is left, 270 is down
	var direction = Vector2(
		cos(angle_radians),  # X component
		-sin(angle_radians)  # Y component (negative since Y increases downward)
	)

	# Calculate final launch vector
	var launch_magnitude = entity_data.launch_strength * entity_data.launch_power
	var launch_vector = direction * launch_magnitude
	
	print("[LaunchCalculator] AngleRad: ", angle_radians, ", Dir: ", direction, ", Mag: ", launch_magnitude, ", Vector: ", launch_vector) # DEBUG PRINT

	return launch_vector
