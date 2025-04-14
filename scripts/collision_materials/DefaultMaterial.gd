# scripts/collision_materials/DefaultMaterial.gd
# Default collision material implementation.
class_name DefaultMaterial
extends RefCounted

# No need to preload ICollisionMaterial as it's globally available via class_name

# Get the material properties
# Returns: Dictionary containing material properties
func get_properties() -> Dictionary:
	# Get default values from PhysicsConfig if available
	var physics_config = load("res://resources/physics/default_physics.tres") as PhysicsConfig
	var friction = 0.5  # Default fallback
	var bounce = 0.5    # Default fallback
	
	if physics_config:
		friction = physics_config.default_material_friction
		bounce = physics_config.default_material_bounce
		
	return {
		"friction": friction,
		"bounce": bounce,
		"sound": "default_impact"
	}
