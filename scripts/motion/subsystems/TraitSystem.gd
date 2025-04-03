class_name TraitSystem
extends RefCounted

# Implement the IMotionSubsystem interface
var _motion_system = null
var _active_traits = {}

func _init() -> void:
	print("[TraitSystem] Initialized")

# Returns the subsystem name for debugging
func get_name() -> String:
	return "TraitSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	print("[TraitSystem] Registered with MotionSystem")

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	print("[TraitSystem] Unregistered from MotionSystem")

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(delta: float) -> Array:
	print("[TraitSystem] Getting continuous modifiers (delta: %.3f)" % delta)
	
	# In a real implementation, this would check active traits and return appropriate modifiers
	# For now, just return a placeholder modifier
	var modifiers = []
	
	# Example: Add a placeholder trait modifier
	var trait_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"TraitSystem",    # source
		"acceleration",   # type
		8,                # priority
		Vector2(0.5, 0),  # vector (faster horizontal acceleration)
		1.1,              # scalar (110% acceleration)
		true,             # is_additive
		-1                # duration (permanent)
	)
	
	modifiers.append(trait_modifier)
	
	return modifiers

# Returns modifiers for collision events
# collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(collision_info: Dictionary) -> Array:
	print("[TraitSystem] Getting collision modifiers")
	
	# In a real implementation, this would check for traits that affect collisions
	# For now, just return an empty array
	return []

# Add a trait to the character
# trait_id: ID of the trait to add
# level: Level of the trait (higher = stronger effect)
func add_trait(trait_id: String, level: int = 1) -> void:
	print("[TraitSystem] Adding trait: id=%s, level=%d" % [trait_id, level])
	_active_traits[trait_id] = level
	# In a real implementation, this would update the character's traits and modifiers

# Remove a trait from the character
# trait_id: ID of the trait to remove
func remove_trait(trait_id: String) -> void:
	if _active_traits.has(trait_id):
		print("[TraitSystem] Removing trait: %s" % trait_id)
		_active_traits.erase(trait_id)
		# In a real implementation, this would update the character's traits and modifiers

# Upgrade a trait to a higher level
# trait_id: ID of the trait to upgrade
# Returns: The new level, or -1 if the trait doesn't exist
func upgrade_trait(trait_id: String) -> int:
	if _active_traits.has(trait_id):
		_active_traits[trait_id] += 1
		print("[TraitSystem] Upgraded trait: %s to level %d" % [trait_id, _active_traits[trait_id]])
		return _active_traits[trait_id]
	return -1
