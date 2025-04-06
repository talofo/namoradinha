class_name ModularBoostSystem
extends RefCounted

# Implement the IMotionSubsystem interface
var _motion_system = null

# Component references
var _entity_data = null
var _calculator = null

func _init() -> void:
	# Initialize components
	_entity_data = load("res://scripts/motion/subsystems/boost_system/data/BoostEntityData.gd").new()
	_calculator = load("res://scripts/motion/subsystems/boost_system/components/BoostCalculator.gd").new()

# Returns the subsystem name for debugging
func get_name() -> String:
	return "BoostSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	# Pass motion system reference to components
	_entity_data.set_motion_system(_motion_system)
	_calculator.set_motion_system(_motion_system)

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	_motion_system = null

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(delta: float) -> Array:
	# Update boost durations and remove expired boosts
	_entity_data.update_boosts(delta)

	# In a real implementation, this would check active boosts and return appropriate modifiers
	var modifiers = []

	# Process each entity with active boosts
	for entity_id in _get_entities_with_active_boosts():
		var entity_data = _entity_data.get_data(entity_id)
		if entity_data.is_empty():
			continue

		# Calculate the combined boost vector for this entity
		var boost_vector = _calculator.calculate_boost_vector(entity_data)

		# Skip if no effective boost
		if boost_vector.length_squared() < 0.01:
			continue

		# Create a boost modifier
		var boost_modifier = load("res://scripts/motion/MotionModifier.gd").new(
			"BoostSystem",  # source
			"velocity",     # type
			10,             # priority
			boost_vector,   # vector (calculated boost)
			1.0,            # scalar
			true,           # is_additive
			-1              # duration (permanent)
		)

		modifiers.append(boost_modifier)

	return modifiers

# Returns modifiers for collision events
# collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	# In a real implementation, this would check for collision-triggered boosts
	# For now, just return an empty array
	return []

# Register an entity with the boost system
# entity_id: Unique identifier for the entity
# Returns: True if registration was successful
func register_entity(entity_id: int) -> bool:
	return _entity_data.register_entity(entity_id)

# Unregister an entity from the boost system
# entity_id: Unique identifier for the entity
# Returns: True if unregistration was successful
func unregister_entity(entity_id: int) -> bool:
	return _entity_data.unregister_entity(entity_id)

# Trigger a manual boost
# entity_id: Unique identifier for the entity
# direction: Direction of the boost
# strength: Strength of the boost
# duration: Duration of the boost in seconds (-1 for permanent)
# Returns: The boost ID, or empty string if failed
func trigger_boost(entity_id: int, direction: Vector2, strength: float, duration: float = -1) -> String:
	return _entity_data.add_boost(entity_id, direction, strength, duration)

# Get all active boosts for an entity
# entity_id: Unique identifier for the entity
# Returns: Array of active boosts, or empty array if entity not found
func get_active_boosts(entity_id: int) -> Array:
	return _entity_data.get_active_boosts(entity_id)

# Get boost history for an entity
# entity_id: Unique identifier for the entity
# Returns: Array of boost history, or empty array if entity not found
func get_boost_history(entity_id: int) -> Array:
	return _entity_data.get_boost_history(entity_id)

# Remove a boost from an entity
# entity_id: Unique identifier for the entity
# boost_id: ID of the boost to remove
# Returns: True if removal was successful
func remove_boost(entity_id: int, boost_id: String) -> bool:
	return _entity_data.remove_boost(entity_id, boost_id)

# Clear all boosts for an entity
# entity_id: Unique identifier for the entity
# Returns: True if clearing was successful
func clear_boosts(entity_id: int) -> bool:
	if not _entity_data.has_entity(entity_id):
		return false

	var active_boosts = _entity_data.get_active_boosts(entity_id)
	var success = true

	for boost in active_boosts:
		if not _entity_data.remove_boost(entity_id, boost.id):
			success = false

	return success

# Get all entities with active boosts
# Returns: Array of entity IDs
func _get_entities_with_active_boosts() -> Array:
	var entities = []

	# Get all entities that have active boosts
	for entity_id in _entity_data._entity_data.keys():
		var entity_data = _entity_data.get_data(entity_id)
		if not entity_data.is_empty() and entity_data.has("active_boosts") and not entity_data.active_boosts.is_empty():
			entities.append(entity_id)

	return entities

# Returns a dictionary of signals this subsystem provides
# The dictionary keys are signal names, values are signal parameter types
# Returns: Dictionary of provided signals
func get_provided_signals() -> Dictionary:
	# BoostSystem doesn't provide any signals
	return {}

# Returns an array of signal dependencies this subsystem needs
# Each entry is a dictionary with:
# - "provider": The name of the subsystem providing the signal
# - "signal_name": The name of the signal to connect to
# - "method": The method in this subsystem to connect to the signal
# Returns: Array of signal dependencies
func get_signal_dependencies() -> Array:
	# BoostSystem doesn't depend on signals from other subsystems
	return []
