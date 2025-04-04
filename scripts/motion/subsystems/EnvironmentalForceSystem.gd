class_name EnvironmentalForceSystem
extends RefCounted

# Implement the IMotionSubsystem interface
# No need for _motion_system variable as it's not used
var _active_zones = {}

func _init() -> void:
	pass

# Returns the subsystem name for debugging
func get_name() -> String:
	return "EnvironmentalForceSystem"

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
	
	# In a real implementation, this would check active environmental zones and return appropriate modifiers
	# For now, just return a placeholder modifier
	var modifiers = []
	
	# Example: Add a placeholder wind force modifier
	var wind_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"EnvironmentalForceSystem",  # source
		"wind",                      # type
		3,                           # priority (low, easily overridden)
		Vector2(2, 0),               # vector (rightward wind)
		1.0,                         # scalar
		true,                        # is_additive
		-1                           # duration (permanent)
	)
	
	modifiers.append(wind_modifier)
	
	# Example: Add a placeholder gravity zone modifier
	var gravity_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"EnvironmentalForceSystem",  # source
		"gravity",                   # type
		4,                           # priority (low, but higher than wind)
		Vector2(0, 0.5),             # vector (increased gravity)
		1.2,                         # scalar (120% gravity)
		true,                        # is_additive
		-1                           # duration (permanent)
	)
	
	modifiers.append(gravity_modifier)
	
	return modifiers

# Returns modifiers for collision events
# _collision_info: Information about the collision (unused)
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	
	# In a real implementation, this would check for environmental effects on collisions
	# For now, just return an empty array
	return []

# Add an environmental force zone
# zone_type: Type of zone (e.g., "wind", "gravity", "turbulence")
# position: Position of the zone
# size: Size of the zone
# force: Force vector of the zone
func add_zone(zone_type: String, position: Vector2, size: Vector2, force: Vector2) -> String:
	var zone_id = "zone_" + str(_active_zones.size())
	
	_active_zones[zone_id] = {
		"type": zone_type,
		"position": position,
		"size": size,
		"force": force
	}
	
	# In a real implementation, this would update the environmental forces
	
	return zone_id

# Remove an environmental force zone
# zone_id: ID of the zone to remove
func remove_zone(zone_id: String) -> bool:
	if _active_zones.has(zone_id):
		_active_zones.erase(zone_id)
		# In a real implementation, this would update the environmental forces
		return true
	return false

# Update an environmental force zone
# zone_id: ID of the zone to update
# force: New force vector for the zone
func update_zone_force(zone_id: String, force: Vector2) -> bool:
	if _active_zones.has(zone_id):
		_active_zones[zone_id].force = force
		# In a real implementation, this would update the environmental forces
		return true
	return false
