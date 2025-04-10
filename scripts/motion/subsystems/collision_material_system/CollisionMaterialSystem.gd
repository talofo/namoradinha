# scripts/motion/subsystems/collision_material_system/CollisionMaterialSystem.gd
# Main entry point for the Collision Material System subsystem.
# Handles material properties for different collision surfaces.
class_name CollisionMaterialSystem
extends RefCounted

# No need to preload DefaultMaterial as it's globally available via class_name

# Implement the IMotionSubsystem interface
# No need for _motion_system variable as it's not used
var _registered_materials = {}

func _init() -> void:
	_register_default_materials()

# Register default material types
func _register_default_materials() -> void:
	# Load the default material from its dedicated class
	var default_material = DefaultMaterial.new()
	_registered_materials = {
		"default": default_material.get_properties(),
		
		# Keep these as inline definitions for now
		# They will be moved to dedicated classes when actually used
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
	pass

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	pass

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(_delta: float) -> Array:
	# In a real implementation, this would check for continuous material effects
	# For now, just return an empty array
	return []

# Returns modifiers for collision events
# collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(collision_info: Dictionary) -> Array:
	
	var modifiers = []

	# Get material type from collision info (default if not specified)
	var material_type = collision_info.get("material", "default")
	var material = _registered_materials.get(material_type, _registered_materials["default"])

	# Add a friction modifier
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
	
	# Add a bounce modifier
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
	
	# Add a sound effect modifier (for playing material-specific sounds)
	var sound_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"CollisionMaterialSystem",  # source
		"sound",                    # type
		5,                          # priority
		Vector2(0, 0),              # vector (no direction change)
		1.0,                        # scalar
		true,                       # is_additive
		0.1                         # duration (short)
	)
	
	modifiers.append(sound_modifier)
	
	return modifiers

# Register a new material type
# material_type: Type of material
# properties: Dictionary of material properties
func register_material(material_type: String, properties: Dictionary) -> void:
	
	# Ensure all required properties are present
	var default_material = _registered_materials["default"]
	var complete_properties = default_material.duplicate()

	for key in properties:
		complete_properties[key] = properties[key]
	
	_registered_materials[material_type] = complete_properties

# Get material properties
# material_type: Type of material
# Returns: Dictionary of material properties, or default if not found
func get_material_properties(material_type: String) -> Dictionary:
	if _registered_materials.has(material_type):
		return _registered_materials[material_type].duplicate()

	return _registered_materials["default"].duplicate()

# Detect material from a collision
# collision_info: Information about the collision
# Returns: The material type as a string
func detect_material_from_collision(collision_info: Dictionary) -> String:
	# In a real implementation, this would check the collision object's properties
	# For now, just return the material from collision_info or "default"
	return collision_info.get("material", "default")

# Update material properties
# material_type: Type of material
# properties: Dictionary of material properties to update
# Returns: True if successful, false if material not found
func update_material(material_type: String, properties: Dictionary) -> bool:
	if _registered_materials.has(material_type):
		for key in properties:
			_registered_materials[material_type][key] = properties[key]

		return true
	return false
