class_name StatusEffectSystem
extends RefCounted

# Implement the IMotionSubsystem interface
var _motion_system = null
var _active_effects = {}

func _init() -> void:
	print("[StatusEffectSystem] Initialized")

# Returns the subsystem name for debugging
func get_name() -> String:
	return "StatusEffectSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	print("[StatusEffectSystem] Registered with MotionSystem")

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	print("[StatusEffectSystem] Unregistered from MotionSystem")

# Process active status effects, removing expired ones
# delta: Time since last frame
func process(delta: float) -> void:
	var effects_to_remove = []
	
	for effect_id in _active_effects:
		var effect = _active_effects[effect_id]
		effect.remaining_time -= delta
		
		if effect.remaining_time <= 0:
			effects_to_remove.append(effect_id)
	
	for effect_id in effects_to_remove:
		print("[StatusEffectSystem] Effect expired: %s" % effect_id)
		_active_effects.erase(effect_id)

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(delta: float) -> Array:
	print("[StatusEffectSystem] Getting continuous modifiers (delta: %.3f)" % delta)
	
	# Process active effects, removing expired ones
	process(delta)
	
	# In a real implementation, this would check active status effects and return appropriate modifiers
	# For now, just return a placeholder modifier
	var modifiers = []
	
	# Example: Add a placeholder status effect modifier
	var slow_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"StatusEffectSystem",  # source
		"velocity",            # type
		25,                    # priority (high, status effects often override other systems)
		Vector2(0, 0),         # vector (no direction change)
		0.7,                   # scalar (70% speed)
		true,                  # is_additive
		2.0                    # duration (2 seconds)
	)
	
	modifiers.append(slow_modifier)
	
	return modifiers

# Returns modifiers for collision events
# collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(collision_info: Dictionary) -> Array:
	print("[StatusEffectSystem] Getting collision modifiers")
	
	# In a real implementation, this would check for status effects that affect collisions
	# For now, just return an empty array
	return []

# Apply a status effect
# effect_type: Type of effect (e.g., "slow", "speed_boost", "low_gravity")
# duration: Duration of the effect in seconds
# strength: Strength of the effect (1.0 = 100%)
func apply_effect(effect_type: String, duration: float, strength: float) -> String:
	var effect_id = "effect_" + str(_active_effects.size())
	print("[StatusEffectSystem] Applying effect: id=%s, type=%s, duration=%.1f, strength=%.2f" % [
		effect_id, effect_type, duration, strength
	])
	
	_active_effects[effect_id] = {
		"type": effect_type,
		"remaining_time": duration,
		"strength": strength
	}
	
	# In a real implementation, this would update the status effects
	
	return effect_id

# Remove a status effect
# effect_id: ID of the effect to remove
func remove_effect(effect_id: String) -> bool:
	if _active_effects.has(effect_id):
		print("[StatusEffectSystem] Removing effect: %s" % effect_id)
		_active_effects.erase(effect_id)
		# In a real implementation, this would update the status effects
		return true
	return false

# Clear all status effects
func clear_all_effects() -> void:
	print("[StatusEffectSystem] Clearing all effects")
	_active_effects.clear()
	# In a real implementation, this would update the status effects
