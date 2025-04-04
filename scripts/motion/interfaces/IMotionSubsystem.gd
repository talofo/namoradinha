class_name IMotionSubsystem
extends RefCounted

# Returns modifiers for frame-based updates
# _delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(_delta: float) -> Array:
	push_error("IMotionSubsystem.get_continuous_modifiers: Method not implemented")
	return []

# Returns modifiers for collision events
# _collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	push_error("IMotionSubsystem.get_collision_modifiers: Method not implemented")
	return []

# Returns the subsystem name for debugging
func get_name() -> String:
	push_error("IMotionSubsystem.get_name: Method not implemented")
	return "UnnamedSubsystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	pass

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	pass
