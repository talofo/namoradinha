class_name ObstacleSystem
extends RefCounted

# Implement the IMotionSubsystem interface
# No need for _motion_system variable as it's not used

func _init() -> void:
	pass

# Returns the subsystem name for debugging
func get_name() -> String:
	return "ObstacleSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	pass

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	pass

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(_delta: float) -> Array:
	
	# In a real implementation, this would check for continuous obstacle effects
	# For now, just return an empty array
	return []

# Returns modifiers for collision events
# _collision_info: Information about the collision (unused)
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	
	# In a real implementation, this would check the collision and return appropriate modifiers
	# For now, just return a placeholder modifier
	var modifiers = []
	
	# Example: Add a placeholder obstacle collision modifier
	var obstacle_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"ObstacleSystem",  # source
		"velocity",        # type
		20,                # priority (higher than boost)
		Vector2(0, -10),   # vector (upward bounce)
		0.8,               # scalar (reduce velocity)
		false,             # is_additive (replace velocity)
		0.5                # duration (half a second)
	)
	
	modifiers.append(obstacle_modifier)
	
	return modifiers

# Register a new obstacle in the system
# _obstacle_type: Type of obstacle
# _position: Position of the obstacle
func register_obstacle(_obstacle_type: String, _position: Vector2) -> void:
	pass
