class_name IMotionSubsystem
extends RefCounted

# Returns modifiers for frame-based updates
# _delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(_delta: float) -> Array:
	return []

# Returns modifiers for collision events
# _collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	return []

# Returns the subsystem name for debugging
func get_name() -> String:
	return "UnnamedSubsystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	pass

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	pass

# Returns a dictionary of signals this subsystem provides
# The dictionary keys are signal names, values are signal parameter types
# Example: { "entity_launched": ["int", "Vector2", "Vector2"] }
# Returns: Dictionary of provided signals
func get_provided_signals() -> Dictionary:
	return {}

# Returns an array of signal dependencies this subsystem needs
# Each entry is a dictionary with:
# - "provider": The name of the subsystem providing the signal
# - "signal_name": The name of the signal to connect to
# - "method": The method in this subsystem to connect to the signal
# Example: [{ "provider": "LaunchSystem", "signal_name": "entity_launched", "method": "record_launch" }]
# Returns: Array of signal dependencies
func get_signal_dependencies() -> Array:
	return []
