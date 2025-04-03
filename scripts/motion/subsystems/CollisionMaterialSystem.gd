class_name CollisionMaterialSystem
extends RefCounted

# Implement the IMotionSubsystem interface
var _motion_system = null
var _registered_materials = {}

func _init() -> void:
	print("[CollisionMaterialSystem] Initialized")
	_register_default_materials()

# Register default material types
func _register_default_materials() -> void:
	_registered_materials = {
		"default": {
			"friction": 1.0,
			"bounce": 0.5,
			"sound": "default_impact"
		},
		"ice": {
			"friction": 0.1,
			"bounce": 0.8,
			"sound": "ice_slide"
		},
		"mud": {
			"friction": 2.0,
			"bounce": 0.2,
			"sound": "mud_impact"
		},
		"rubber": {
			"friction": 1.5,
			"bounce": 0.9,
			"sound": "rubber_bounce"
		}
	}

# Returns the subsystem name for debugging
func get_name() -> String:
	return "CollisionMaterialSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	print("[CollisionMaterialSystem] Registered with MotionSystem")

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	print("[CollisionMaterialSystem] Unregistered from MotionSystem")

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(delta: float) -> Array:
	print("[CollisionMaterialSystem] Getting continuous modifiers (delta: %.3f)" % delta)
	
	# In a real implementation, this would check for continuous material effects
	# For now, just return an empty array
	return []

# Returns modifiers for collision events
# collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(collision_info: Dictionary) -> Array:
	print("[CollisionMaterialSystem] Getting collision modifiers")
	
	# In a real implementation, this would check the collision material and return appropriate modifiers
	# For now, just return placeholder modifiers
	var modifiers = []
	
	# Get material type from collision info (default if not specified)
	var material_type = collision_info.get("material", "default")
	var material = _registered_materials.get(material_type, _registered_materials["default"])
	
	# Example: Add a placeholder friction modifier
	var friction_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"CollisionMaterialSystem",  # source
		"friction",                 # type
		12,                         # priority
		Vector2(0, 0),              # vector (no direction change)
		material.friction,          # scalar (material-specific friction)
		false,                      # is_additive (replace friction)
		-1                          # duration (permanent)
	)
	
	modifiers.append(friction_modifier)
	
	# Example: Add a placeholder bounce modifier
	var bounce_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"CollisionMaterialSystem",  # source
		"bounce",                   # type
		12,                         # priority
		Vector2(0, 0),              # vector (no direction change)
		material.bounce,            # scalar (material-specific bounce)
		false,                      # is_additive (replace bounce)
		-1                          # duration (permanent)
	)
	
	modifiers.append(bounce_modifier)
	
	return modifiers

# Register a new material type
# material_type: Type of material
# properties: Dictionary of material properties
func register_material(material_type: String, properties: Dictionary) -> void:
	print("[CollisionMaterialSystem] Registering material: type=%s, properties=%s" % [
		material_type, properties
	])
	
	_registered_materials[material_type] = properties
	# In a real implementation, this would update the material registry

# Get material properties
# material_type: Type of material
# Returns: Dictionary of material properties, or null if not found
func get_material_properties(material_type: String) -> Dictionary:
	if _registered_materials.has(material_type):
		return _registered_materials[material_type].duplicate()
	return {}

# Update material properties
# material_type: Type of material
# properties: Dictionary of material properties to update
# Returns: True if successful, false if material not found
func update_material(material_type: String, properties: Dictionary) -> bool:
	if _registered_materials.has(material_type):
		print("[CollisionMaterialSystem] Updating material: type=%s, properties=%s" % [
			material_type, properties
		])
		
		for key in properties:
			_registered_materials[material_type][key] = properties[key]
		
		# In a real implementation, this would update the material registry
		return true
	return false
