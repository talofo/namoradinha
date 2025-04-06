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
	if entity_data.is_empty():
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

	return launch_vector
