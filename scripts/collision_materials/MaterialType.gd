class_name MaterialType
extends Node

## The type of material this object is made of.
## Valid values: "default", "ice", "mud", "rubber", or any custom material registered with CollisionMaterialSystem.
@export var material_type: String = "default"

## Whether to apply this material to the parent node automatically.
@export var apply_to_parent: bool = true

func _ready() -> void:
	if apply_to_parent and get_parent():
		# Add the material_type property to the parent node
		get_parent().set("material_type", material_type)
		
		# Optionally add to a group for easier querying
		if not get_parent().is_in_group(material_type):
			get_parent().add_to_group(material_type)

## Get the material type
func get_material_type() -> String:
	return material_type

## Set the material type
func set_material_type(type: String) -> void:
	material_type = type
	
	# Update parent if apply_to_parent is enabled
	if apply_to_parent and get_parent():
		get_parent().set("material_type", material_type)
		
		# Remove from old group if in one
		for group in get_parent().get_groups():
			if group in ["default", "ice", "mud", "rubber"]:
				get_parent().remove_from_group(group)
		
		# Add to new group
		if not get_parent().is_in_group(material_type):
			get_parent().add_to_group(material_type)
