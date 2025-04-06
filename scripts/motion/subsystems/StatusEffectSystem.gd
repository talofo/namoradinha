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
var _entity_states = {}

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

# Update entity states based on physics
# entity_id: Unique identifier for the entity
# velocity: Current velocity of the entity
# collision_info: Information about the collision (optional)
# Returns: Dictionary of entity states
func update_entity_states(entity_id: int, velocity: Vector2, collision_info: Dictionary = {}) -> Dictionary:
	if not _entity_states.has(entity_id):
		_entity_states[entity_id] = {
			"is_bouncing": false,
			"is_sliding": false,
			"is_launched": false,
			"active_effects": {},
			"previous_velocity": Vector2.ZERO,
			"time_in_state": {
				"bouncing": 0.0,
				"sliding": 0.0,
				"launched": 0.0
			}
		}
	
	var states = _entity_states[entity_id]
	var previous_states = {
		"is_bouncing": states.is_bouncing,
		"is_sliding": states.is_sliding,
		"is_launched": states.is_launched
	}
	
	# Store previous velocity for acceleration calculations
	states.previous_velocity = velocity
	
	# Determine if bouncing (moving upward significantly)
	states.is_bouncing = velocity.y < -5.0
	
	# Determine if sliding (moving horizontally with minimal vertical movement)
	states.is_sliding = (abs(velocity.y) < 5.0 and abs(velocity.x) > 5.0)
	
	# Determine if launched (significant movement in any direction)
	states.is_launched = velocity.length() > 10.0
	
	# If we have collision info, refine the sliding state
	if collision_info.has("normal"):
		var normal = collision_info.get("normal", Vector2.ZERO)
		states.is_sliding = states.is_sliding and normal.y < -0.7  # Only slide on floor-like surfaces
	
	# Update state timers
	if states.is_bouncing != previous_states.is_bouncing and states.is_bouncing:
		# Reset time in bouncing state
		states.time_in_state.bouncing = 0.0
	
	if states.is_sliding != previous_states.is_sliding and states.is_sliding:
		# Reset time in sliding state
		states.time_in_state.sliding = 0.0
	
	if states.is_launched != previous_states.is_launched and states.is_launched:
		# Reset time in launched state
		states.time_in_state.launched = 0.0
	
	return states

# Get the current states for an entity
# entity_id: Unique identifier for the entity
# Returns: Dictionary of entity states, or empty dictionary if not found
func get_entity_states(entity_id: int) -> Dictionary:
	if not _entity_states.has(entity_id):
		return {}
	
	# Return a simplified version with just the state flags
	var states = _entity_states[entity_id]
	return {
		"is_bouncing": states.is_bouncing,
		"is_sliding": states.is_sliding,
		"is_launched": states.is_launched
	}

# Update state timers
# delta: Time since last frame
func update_state_timers(delta: float) -> void:
	for entity_id in _entity_states:
		var states = _entity_states[entity_id]
		
		# Update time in each state
		if states.is_bouncing:
			states.time_in_state.bouncing += delta
		
		if states.is_sliding:
			states.time_in_state.sliding += delta
		
		if states.is_launched:
			states.time_in_state.launched += delta

# Clear states for an entity
# entity_id: Unique identifier for the entity
func clear_entity_states(entity_id: int) -> void:
	if _entity_states.has(entity_id):
		_entity_states.erase(entity_id)
