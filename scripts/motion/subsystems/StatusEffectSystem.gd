class_name StatusEffectSystem
extends RefCounted

# Implement the IMotionSubsystem interface
# No need for _motion_system variable as it's not used
var _active_effects = {}

# Entity state storage
# Structure:
# {
#   entity_id: {
#     is_bouncing: bool,
#     is_sliding: bool,
#     is_launched: bool,
#     active_effects: Dictionary
#   }
# }
# var _entity_states = {} # Removed - State logic moved to MotionStateManager / PlayerCharacter

func _init() -> void:
	pass

# Returns the subsystem name for debugging
func get_name() -> String:
	return "StatusEffectSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	pass

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	pass

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
		_active_effects.erase(effect_id)

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(delta: float) -> Array:
	
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
# _collision_info: Information about the collision (unused)
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	
	# In a real implementation, this would check for status effects that affect collisions
	# For now, just return an empty array
	return []

# Apply a status effect
# effect_type: Type of effect (e.g., "slow", "speed_boost", "low_gravity")
# duration: Duration of the effect in seconds
# strength: Strength of the effect (1.0 = 100%)
func apply_effect(effect_type: String, duration: float, strength: float) -> String:
	var effect_id = "effect_" + str(_active_effects.size())
	
	_active_effects[effect_id] = {
		"type": effect_type,
		"remaining_time": duration,
		"strength": strength
	}

	return effect_id

# Remove a status effect
# effect_id: ID of the effect to remove
func remove_effect(effect_id: String) -> bool:
	if _active_effects.has(effect_id):
		_active_effects.erase(effect_id)
		return true
	return false

# Clear all status effects
func clear_all_effects() -> void:
	_active_effects.clear()

# --- Removed State Management Logic ---
# The following functions were removed as state determination (bouncing, sliding, launched)
# is now handled by MotionStateManager and state variables are managed externally (e.g., PlayerCharacter).
# - update_entity_states
# - get_entity_states
# - update_state_timers
# - clear_entity_states
# The _entity_states dictionary was also removed.
# This class now focuses solely on managing status effects (_active_effects).
