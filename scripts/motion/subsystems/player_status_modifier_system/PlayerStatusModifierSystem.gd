# scripts/motion/subsystems/player_status_modifier_system/PlayerStatusModifierSystem.gd
# Main entry point for the Player Status Modifier System subsystem.
# Handles temporary status modifiers that affect player attributes and behavior.
class_name PlayerStatusModifierSystem
extends RefCounted

# Implement the IMotionSubsystem interface
# No need for _motion_system variable as it's not used
var _active_modifiers = {}

func _init() -> void:
	pass

# Returns the subsystem name for debugging
func get_name() -> String:
	return "PlayerStatusModifierSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	pass

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	pass

# Process active status modifiers, removing expired ones
# delta: Time since last frame
func process(delta: float) -> void:
	var modifiers_to_remove = []
	
	for modifier_id in _active_modifiers:
		var modifier = _active_modifiers[modifier_id]
		modifier.remaining_time -= delta
		
		if modifier.remaining_time <= 0:
			modifiers_to_remove.append(modifier_id)
	
	for modifier_id in modifiers_to_remove:
		_active_modifiers.erase(modifier_id)

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(delta: float) -> Array:
	
	# Process active modifiers, removing expired ones
	process(delta)
	
	# In a real implementation, this would check active status modifiers and return appropriate modifiers
	# For now, just return a placeholder modifier
	var modifiers = []
	
	# Example: Add a placeholder status modifier
	var slow_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"PlayerStatusModifierSystem",  # source
		"velocity",                    # type
		25,                            # priority (high, status modifiers often override other systems)
		Vector2(0, 0),                 # vector (no direction change)
		0.7,                           # scalar (70% speed)
		true,                          # is_additive
		2.0                            # duration (2 seconds)
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

# Apply a status modifier
# modifier_type: Type of modifier (e.g., "slow", "speed_boost", "shield", "invincibility")
# duration: Duration of the modifier in seconds
# strength: Strength of the modifier (1.0 = 100%)
func apply_modifier(modifier_type: String, duration: float, strength: float) -> String:
	var modifier_id = "modifier_" + str(_active_modifiers.size())
	
	_active_modifiers[modifier_id] = {
		"type": modifier_type,
		"remaining_time": duration,
		"strength": strength
	}

	return modifier_id

# Remove a status modifier
# modifier_id: ID of the modifier to remove
func remove_modifier(modifier_id: String) -> bool:
	if _active_modifiers.has(modifier_id):
		_active_modifiers.erase(modifier_id)
		return true
	return false

# Clear all status modifiers
func clear_all_modifiers() -> void:
	_active_modifiers.clear()

# --- Removed State Management Logic ---
# The following functions were removed as state determination (bouncing, sliding, launched)
# is now handled by MotionStateManager and state variables are managed externally (e.g., PlayerCharacter).
# - update_entity_states
# - get_entity_states
# - update_state_timers
# - clear_entity_states
# The _entity_states dictionary was also removed.
# This class now focuses solely on managing player status modifiers (_active_modifiers).
