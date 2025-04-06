class_name EquipmentSystem
extends RefCounted

# Implement the IMotionSubsystem interface
# No need for _motion_system variable as it's not used
var _equipped_items = {}

func _init() -> void:
	pass

# Returns the subsystem name for debugging
func get_name() -> String:
	return "EquipmentSystem"

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
	
	# In a real implementation, this would check equipped items and return appropriate modifiers
	# For now, just return a placeholder modifier
	var modifiers = []
	
	# Example: Add a placeholder equipment modifier
	var equipment_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"EquipmentSystem",  # source
		"gravity",          # type
		5,                  # priority
		Vector2(0, -1),     # vector (reduced gravity)
		0.9,                # scalar (90% of normal gravity)
		true,               # is_additive
		-1                  # duration (permanent)
	)
	
	modifiers.append(equipment_modifier)
	
	return modifiers

# Returns modifiers for collision events
# _collision_info: Information about the collision (unused)
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	
	# In a real implementation, this would check for equipment that affects collisions
	# For now, just return a placeholder modifier
	var modifiers = []
	
	# Example: Add a placeholder equipment collision modifier
	var bounce_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"EquipmentSystem",  # source
		"bounce",           # type
		15,                 # priority
		Vector2(0, 0),      # vector (no direction change)
		1.2,                # scalar (120% bounce efficiency)
		true,               # is_additive
		-1                  # duration (permanent)
	)
	
	modifiers.append(bounce_modifier)
	
	return modifiers

# Equip an item
# item_id: ID of the item to equip
# slot: Slot to equip the item in
func equip_item(item_id: String, slot: String) -> void:
	_equipped_items[slot] = item_id

# Unequip an item
# slot: Slot to unequip
func unequip_item(slot: String) -> void:
	if _equipped_items.has(slot):
		_equipped_items.erase(slot)
