# scripts/motion/subsystems/obstacle_system/components/ObstacleTypeRegistry.gd
# Component responsible for managing the registration of different obstacle types.
class_name ObstacleTypeRegistry
extends RefCounted

# Dictionary to store registered obstacle types { "type_name": IObstacleType_instance }
var _obstacle_types: Dictionary = {}

# Registers an obstacle type instance with a given name.
# type_name: The unique string identifier for the obstacle type (e.g., "weakener").
# obstacle_type: An instance of a class implementing IObstacleType interface.
func register_obstacle_type(type_name: String, obstacle_type) -> void:
	# Check if the obstacle_type has the required methods instead of type checking
	if not obstacle_type.has_method("apply_effect") or not obstacle_type.has_method("can_affect"):
		push_error("Attempted to register an invalid obstacle type for '%s'. Must implement apply_effect and can_affect methods." % type_name)
		return
	if _obstacle_types.has(type_name):
		push_warning("Overwriting existing obstacle type registration for '%s'." % type_name)
	_obstacle_types[type_name] = obstacle_type

# Unregisters an obstacle type by its name.
# type_name: The name of the obstacle type to remove.
func unregister_obstacle_type(type_name: String) -> void:
	if _obstacle_types.has(type_name):
		_obstacle_types.erase(type_name)
	else:
		push_warning("Attempted to unregister non-existent obstacle type '%s'." % type_name)

# Checks if an obstacle type with the given name is registered.
# type_name: The name of the obstacle type to check.
# Returns: True if the type is registered, false otherwise.
func has_obstacle_type(type_name: String) -> bool:
	return _obstacle_types.has(type_name)

# Retrieves a registered obstacle type instance by its name.
# type_name: The name of the obstacle type to retrieve.
# Returns: The obstacle type instance, or null if not found.
func get_obstacle_type(type_name: String):
	if not has_obstacle_type(type_name):
		return null
	return _obstacle_types[type_name]

# Retrieves a copy of the dictionary containing all registered obstacle types.
# Returns: A Dictionary mapping type names to IObstacleType instances.
func get_all_obstacle_types() -> Dictionary:
	return _obstacle_types.duplicate()
