class_name ObstacleSystem
extends RefCounted

# Implement the IMotionSubsystem interface
var _motion_system = null

func _init() -> void:
	print("[ObstacleSystem] Initialized")

# Returns the subsystem name for debugging
func get_name() -> String:
	return "ObstacleSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	print("[ObstacleSystem] Registered with MotionSystem")

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	print("[ObstacleSystem] Unregistered from MotionSystem")

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(delta: float) -> Array:
	print("[ObstacleSystem] Getting continuous modifiers (delta: %.3f)" % delta)
	
	# In a real implementation, this would check for continuous obstacle effects
	# For now, just return an empty array
	return []

# Returns modifiers for collision events
# collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(collision_info: Dictionary) -> Array:
	print("[ObstacleSystem] Getting collision modifiers")
	
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
# obstacle_type: Type of obstacle
# position: Position of the obstacle
func register_obstacle(obstacle_type: String, position: Vector2) -> void:
	print("[ObstacleSystem] Registering obstacle: type=%s, position=%s" % [obstacle_type, position])
	# In a real implementation, this would add the obstacle to a list of active obstacles
