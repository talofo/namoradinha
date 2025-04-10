# scripts/motion/subsystems/boost_system/components/BoostTypeRegistry.gd
# Component responsible for managing the registration of different boost types.
class_name BoostTypeRegistry
extends RefCounted

# No need to preload IBoostType as it's globally available via class_name

# Dictionary to store registered boost types { "type_name": IBoostType_instance }
var _boost_types: Dictionary = {}

# Registers a boost type instance with a given name.
# type_name: The unique string identifier for the boost type (e.g., "manual_air").
# boost_type: An instance of a class implementing IBoostType interface (has required methods).
func register_boost_type(type_name: String, boost_type) -> void:
	# Check if the boost_type has the required methods instead of type checking
	if not boost_type.has_method("can_apply_boost") or not boost_type.has_method("calculate_boost_vector"):
		push_error("Attempted to register an invalid boost type for '%s'. Must implement can_apply_boost and calculate_boost_vector methods." % type_name)
		return
	if _boost_types.has(type_name):
		push_warning("Overwriting existing boost type registration for '%s'." % type_name)
	_boost_types[type_name] = boost_type

# Unregisters a boost type by its name.
# type_name: The name of the boost type to remove.
func unregister_boost_type(type_name: String) -> void:
	if _boost_types.has(type_name):
		_boost_types.erase(type_name)
	else:
		push_warning("Attempted to unregister non-existent boost type '%s'." % type_name)

# Checks if a boost type with the given name is registered.
# type_name: The name of the boost type to check.
# Returns: True if the type is registered, false otherwise.
func has_boost_type(type_name: String) -> bool:
	return _boost_types.has(type_name)

# Retrieves a registered boost type instance by its name.
# type_name: The name of the boost type to retrieve.
# Returns: The boost type instance, or null if not found.
func get_boost_type(type_name: String):
	if not has_boost_type(type_name):
		# Error already pushed in BoostSystem, avoid duplicate messages if called from there.
		# Consider if an error here is still useful for direct calls.
		# push_error("Boost type not found: " + type_name)
		return null
	return _boost_types[type_name]

# Retrieves a copy of the dictionary containing all registered boost types.
# Returns: A Dictionary mapping type names to IBoostType instances.
func get_all_boost_types() -> Dictionary:
	return _boost_types.duplicate(true) # Deep copy if instances are complex, shallow otherwise
