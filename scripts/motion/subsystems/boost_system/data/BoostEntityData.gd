class_name BoostEntityData
extends RefCounted

# Entity boost data storage
# Structure:
# {
#   entity_id: {
#     active_boosts: Array[Dictionary],
#     boost_history: Array[Dictionary]
#   }
# }
var _entity_data = {}

# Reference to motion system for config access
var _motion_system = null

func set_motion_system(motion_system) -> void:
	_motion_system = motion_system

# Register an entity with the boost system
# entity_id: Unique identifier for the entity
# Returns: True if registration was successful
func register_entity(entity_id: int) -> bool:
	if _entity_data.has(entity_id):
		return false

	_entity_data[entity_id] = {
		"active_boosts": [],
		"boost_history": []
	}
	return true

# Unregister an entity from the boost system
# entity_id: Unique identifier for the entity
# Returns: True if unregistration was successful
func unregister_entity(entity_id: int) -> bool:
	if not _entity_data.has(entity_id):
		return false

	_entity_data.erase(entity_id)
	return true

# Add a boost to an entity
# entity_id: Unique identifier for the entity
# direction: Direction of the boost
# strength: Strength of the boost
# duration: Duration of the boost in seconds (-1 for permanent)
# Returns: The boost ID, or empty string if failed
func add_boost(entity_id: int, direction: Vector2, strength: float, duration: float = -1) -> String:
	if not _entity_data.has(entity_id):
		register_entity(entity_id)

	var entity_boosts = _entity_data[entity_id]
	var boost_id = "boost_" + str(entity_id) + "_" + str(entity_boosts.active_boosts.size())

	var boost = {
		"id": boost_id,
		"direction": direction,
		"strength": strength,
		"duration": duration,
		"remaining_time": duration,
		"created_at": Time.get_unix_time_from_system()
	}

	entity_boosts.active_boosts.append(boost)

	return boost_id

# Remove a boost from an entity
# entity_id: Unique identifier for the entity
# boost_id: ID of the boost to remove
# Returns: True if removal was successful
func remove_boost(entity_id: int, boost_id: String) -> bool:
	if not _entity_data.has(entity_id):
		return false

	var entity_boosts = _entity_data[entity_id]
	var boost_index = -1

	for i in range(entity_boosts.active_boosts.size()):
		if entity_boosts.active_boosts[i].id == boost_id:
			boost_index = i
			break

	if boost_index == -1:
		return false

	# Move the boost to history before removing
	var boost = entity_boosts.active_boosts[boost_index]
	boost.removed_at = Time.get_unix_time_from_system()
	entity_boosts.boost_history.append(boost)

	# Remove the boost from active boosts
	entity_boosts.active_boosts.remove_at(boost_index)

	return true

# Update boost durations and remove expired boosts
# delta: Time since last frame
# Returns: Array of expired boost IDs
func update_boosts(delta: float) -> Array:
	var expired_boosts = []

	for entity_id in _entity_data:
		var entity_boosts = _entity_data[entity_id]
		var boosts_to_remove = []

		for boost in entity_boosts.active_boosts:
			# Skip permanent boosts
			if boost.duration < 0:
				continue

			boost.remaining_time -= delta

			if boost.remaining_time <= 0:
				boosts_to_remove.append(boost.id)
				expired_boosts.append({
					"entity_id": entity_id,
					"boost_id": boost.id
				})

		# Remove expired boosts
		for boost_id_to_remove in boosts_to_remove: # Use different variable name to avoid conflict
			remove_boost(entity_id, boost_id_to_remove)

	return expired_boosts

# Get all active boosts for an entity
# entity_id: Unique identifier for the entity
# Returns: Array of active boosts, or empty array if entity not found
func get_active_boosts(entity_id: int) -> Array:
	if not _entity_data.has(entity_id):
		return []

	return _entity_data[entity_id].active_boosts.duplicate()

# Get boost history for an entity
# entity_id: Unique identifier for the entity
# Returns: Array of boost history, or empty array if entity not found
func get_boost_history(entity_id: int) -> Array:
	if not _entity_data.has(entity_id):
		return []

	return _entity_data[entity_id].boost_history.duplicate()

# Check if an entity is registered
# entity_id: Unique identifier for the entity
# Returns: True if the entity is registered
func has_entity(entity_id: int) -> bool:
	return _entity_data.has(entity_id)

# Get the data for an entity
# entity_id: Unique identifier for the entity
# Returns: The entity data, or an empty dictionary if not found
func get_data(entity_id: int) -> Dictionary:
	if not _entity_data.has(entity_id):
		return {}

	return _entity_data[entity_id]
