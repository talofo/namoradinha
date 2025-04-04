class_name BoostSystem
extends RefCounted

const MotionModifierScript = preload("res://scripts/motion/MotionModifier.gd")

# Implement the IMotionSubsystem interface
var _motion_system = null

func _init() -> void:
	print("[BoostSystem] Initialized")

# Returns the subsystem name for debugging
func get_name() -> String:
	return "BoostSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register(motion_system) -> void:
	_motion_system = motion_system
	print("[BoostSystem] Registered with MotionSystem")

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	print("[BoostSystem] Unregistered from MotionSystem")

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(delta: float) -> Array:
	print("[BoostSystem] Getting continuous modifiers (delta: %.3f)" % delta)
	
	# In a real implementation, this would check active boosts and return appropriate modifiers
	# For now, just return a placeholder modifier
	var modifiers = []
	
	# Example: Add a placeholder boost modifier
	var boost_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"BoostSystem",  # source
		"velocity",     # type
		10,             # priority
		Vector2(5, 0),  # vector (rightward boost)
		1.0,            # scalar
		true,           # is_additive
		-1              # duration (permanent)
	)
	
	modifiers.append(boost_modifier)
	
	return modifiers

# Returns modifiers for collision events
# collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	print("[BoostSystem] Getting collision modifiers")
	
	# In a real implementation, this would check for collision-triggered boosts
	# For now, just return an empty array
	return []

# Trigger a manual boost (would be called by player input)
# direction: Direction of the boost
# strength: Strength of the boost
func trigger_boost(direction: Vector2, strength: float) -> void:
	print("[BoostSystem] Triggering boost: direction=%s, strength=%.2f" % [direction, strength])
	# In a real implementation, this would create a new active boost
