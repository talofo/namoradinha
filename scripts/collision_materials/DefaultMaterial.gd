# scripts/collision_materials/DefaultMaterial.gd
# Default collision material implementation.
class_name DefaultMaterial
extends RefCounted

# No need to preload ICollisionMaterial as it's globally available via class_name

# Get the material properties
# Returns: Dictionary containing material properties
func get_properties() -> Dictionary:
	return {
		"friction": 0.5,  # Reduced friction to make sliding last longer
		"bounce": 0.5,
		"sound": "default_impact"
	}
