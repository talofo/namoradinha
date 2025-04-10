# scripts/motion/subsystems/collision_material_system/interfaces/ICollisionMaterial.gd
# Interface for collision material types.
class_name ICollisionMaterial
extends RefCounted

# Get the material properties
# Returns: Dictionary containing material properties (friction, bounce, sound, etc.)
func get_properties() -> Dictionary:
	push_error("ICollisionMaterial.get_properties() is not implemented")
	return {}
