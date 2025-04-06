class_name BounceEntityData
extends RefCounted

# Entity bounce data storage
# Structure:
# {
#   entity_id: {
#     bounce_count: int,
#     launch_position_y: float,
#     floor_position_y: float,
#     max_height_y: float,
#     current_target_height: float,
#     launch_velocity: Vector2
#   }
# }
var _entity_data = {}

# Reference to motion system for config access
var _motion_system = null

func set_motion_system(motion_system) -> void:
	_motion_system = motion_system

# Register an entity with the bounce system
# entity_id: Unique identifier for the entity
# position: Initial position of the entity
# Returns: True if registration was successful
func register_entity(entity_id: int, position: Vector2) -> bool:
	if _entity_data.has(entity_id):
		return false

	_entity_data[entity_id] = {
		"bounce_count": 0,
		"launch_position_y": position.y,
		"floor_position_y": position.y,
		"max_height_y": position.y,
		"current_target_height": 0.0,
		"launch_velocity": Vector2.ZERO
	}
	return true

# Unregister an entity from the bounce system
# entity_id: Unique identifier for the entity
# Returns: True if unregistration was successful
func unregister_entity(entity_id: int) -> bool:
	if not _entity_data.has(entity_id):
		return false

	_entity_data.erase(entity_id)
	return true

# Record a launch for an entity
# entity_id: Unique identifier for the entity
# velocity: Launch velocity
# position: Launch position
func record_launch(entity_id: int, velocity: Vector2, position: Vector2) -> void:
	if not _entity_data.has(entity_id):
		register_entity(entity_id, position)

	var bounce_data = _entity_data[entity_id]
	bounce_data.bounce_count = 0
	bounce_data.launch_velocity = velocity
	bounce_data.launch_position_y = position.y
	bounce_data.floor_position_y = position.y
	bounce_data.max_height_y = position.y
	bounce_data.current_target_height = 0.0

# Update the maximum height reached by an entity
# entity_id: Unique identifier for the entity
# position: Current position of the entity
func update_max_height(entity_id: int, position: Vector2) -> void:
	if not _entity_data.has(entity_id):
		return

	var bounce_data = _entity_data[entity_id]
	if position.y < bounce_data.max_height_y:
		bounce_data.max_height_y = position.y

# Force reset the maximum height for an entity
# entity_id: Unique identifier for the entity
# position: The position to reset to
func force_reset_max_height(entity_id: int, position: Vector2) -> void:
	if not _entity_data.has(entity_id):
		return

	_entity_data[entity_id].max_height_y = position.y

# Get the current bounce count for an entity
# entity_id: Unique identifier for the entity
# Returns: The current bounce count, or -1 if the entity is not registered
func get_bounce_count(entity_id: int) -> int:
	if not _entity_data.has(entity_id):
		return -1

	return _entity_data[entity_id].bounce_count

# Get the data for an entity
# entity_id: Unique identifier for the entity
# Returns: The entity data, or an empty dictionary if not found
func get_data(entity_id: int) -> Dictionary:
	if not _entity_data.has(entity_id):
		return {}

	return _entity_data[entity_id]

# Update floor position for an entity
# entity_id: Unique identifier for the entity
# position: The floor position
func update_floor_position(entity_id: int, position: Vector2) -> void:
	if not _entity_data.has(entity_id):
		return

	_entity_data[entity_id].floor_position_y = position.y

# Increment bounce count for an entity
# entity_id: Unique identifier for the entity
func increment_bounce_count(entity_id: int) -> void:
	if not _entity_data.has(entity_id):
		return

	_entity_data[entity_id].bounce_count += 1

# Update target height for an entity
# entity_id: Unique identifier for the entity
# target_height: The new target height
func update_target_height(entity_id: int, target_height: float) -> void:
	if not _entity_data.has(entity_id):
		return

	_entity_data[entity_id].current_target_height = target_height

# Check if an entity is registered
# entity_id: Unique identifier for the entity
# Returns: True if the entity is registered
func has_entity(entity_id: int) -> bool:
	return _entity_data.has(entity_id)
