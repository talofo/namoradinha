# scripts/motion/subsystems/collision_material_system/CollisionMaterialSystem.gd
# Main entry point for the Collision Material System subsystem.
# Handles material properties for different collision surfaces.
class_name CollisionMaterialSystem
extends RefCounted

# No need to preload DefaultMaterial as it's globally available via class_name

# Implement the IMotionSubsystem interface
var _registered_materials = {}
var _motion_profile_resolver: MotionProfileResolver = null # Resolver reference (still needed?)
var _physics_config: PhysicsConfig = null # Reference to the main physics config
var _core = null # Reference to MotionSystemCore (potentially redundant if we have _physics_config)

# Default constants (used only if PhysicsConfig is missing)
const DEFAULT_FRICTION = 0.5
const DEFAULT_BOUNCE = 0.5
const ICE_FRICTION = 0.1
const ICE_BOUNCE = 0.8
const MUD_FRICTION = 2.0
const MUD_BOUNCE = 0.2
const RUBBER_FRICTION = 1.5
const RUBBER_BOUNCE = 0.9

func _init() -> void:
	# Materials are now registered/updated when PhysicsConfig is set
	pass

# Initialize with the MotionProfileResolver (May not be needed anymore for materials)
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
	_motion_profile_resolver = resolver
	# No longer refreshing materials here, happens in set_physics_config
	if Engine.is_editor_hint() or OS.is_debug_build():
		print("[DEBUG] CollisionMaterialSystem: MotionProfileResolver initialized (used for?).")

# Set the PhysicsConfig and update material properties
func set_physics_config(config: PhysicsConfig) -> void:
	if config is PhysicsConfig:
		_physics_config = config
		_update_materials_from_config()
		if Engine.is_editor_hint() or OS.is_debug_build():
			print("[DEBUG] CollisionMaterialSystem: PhysicsConfig set and materials updated.")
	else:
		push_error("CollisionMaterialSystem: Invalid PhysicsConfig provided.")
		_register_default_materials() # Fallback to defaults if config is invalid

# Update material properties using the PhysicsConfig
func _update_materials_from_config() -> void:
	if not _physics_config:
		push_warning("CollisionMaterialSystem: Cannot update materials, PhysicsConfig is null.")
		_register_default_materials() # Fallback
		return

	# Use get_param for safety, falling back to constants
	_registered_materials["default"] = {
		"friction": _physics_config.get_param("default_material_friction", "default") if _physics_config else DEFAULT_FRICTION,
		"bounce": _physics_config.get_param("default_material_bounce", "default") if _physics_config else DEFAULT_BOUNCE,
		"sound": "default_impact" # Assuming a default sound
	}
	_registered_materials["ice"] = {
		"friction": _physics_config.get_param("ice_material_friction", "default") if _physics_config else ICE_FRICTION,
		"bounce": _physics_config.get_param("ice_material_bounce", "default") if _physics_config else ICE_BOUNCE,
		"sound": "ice_slide"
	}
	_registered_materials["mud"] = {
		"friction": _physics_config.get_param("mud_material_friction", "default") if _physics_config else MUD_FRICTION,
		"bounce": _physics_config.get_param("mud_material_bounce", "default") if _physics_config else MUD_BOUNCE,
		"sound": "mud_impact"
	}
	_registered_materials["rubber"] = {
		"friction": _physics_config.get_param("rubber_material_friction", "default") if _physics_config else RUBBER_FRICTION,
		"bounce": _physics_config.get_param("rubber_material_bounce", "default") if _physics_config else RUBBER_BOUNCE,
		"sound": "rubber_bounce"
	}
	
	if Engine.is_editor_hint() or OS.is_debug_build():
		print("[DEBUG] CollisionMaterialSystem: Updated materials from PhysicsConfig:")
		for mat_type in _registered_materials:
			print("  - %s: %s" % [mat_type, _registered_materials[mat_type]])


# Fallback: Register default material types using constants
func _register_default_materials() -> void:
	push_warning("CollisionMaterialSystem: Using fallback default material properties.")
	_registered_materials = {
		"default": { "friction": DEFAULT_FRICTION, "bounce": DEFAULT_BOUNCE, "sound": "default_impact" },
		"ice": { "friction": ICE_FRICTION, "bounce": ICE_BOUNCE, "sound": "ice_slide" },
		"mud": { "friction": MUD_FRICTION, "bounce": MUD_BOUNCE, "sound": "mud_impact" },
		"rubber": { "friction": RUBBER_FRICTION, "bounce": RUBBER_BOUNCE, "sound": "rubber_bounce" }
	}

# Returns the subsystem name for debugging
func get_name() -> String:
	return "CollisionMaterialSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	# Store reference to MotionSystemCore for accessing PhysicsConfig
	if "_motion_system" in self and self._motion_system:
		_core = self._motion_system

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	_core = null

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
