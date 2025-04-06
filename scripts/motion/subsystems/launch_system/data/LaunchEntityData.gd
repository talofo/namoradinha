class_name LaunchEntityData
extends RefCounted

# Entity launch data storage
# Structure:
# {
#   entity_id: {
#     launch_power: float,
#     launch_angle_degrees: float,
#     launch_strength: float,
#     last_launch_vector: Vector2,
#     last_launch_time: float
#   }
# }
var _entity_data = {}

# Default launch configuration
var default_launch_strength: float = 1500.0
var default_launch_angle_degrees: float = 45.0

# Reference to motion system for config access
var _motion_system = null

func set_motion_system(motion_system) -> void:
    _motion_system = motion_system

# Register an entity with the launch system
# entity_id: Unique identifier for the entity
# Returns: True if registration was successful
func register_entity(entity_id: int) -> bool:
    if _entity_data.has(entity_id):
        return false
    
    # Get current defaults dynamically from config if possible
    var current_angle = default_launch_angle_degrees # Fallback
    var current_strength = default_launch_strength # Fallback
    if _motion_system and _motion_system.has_method("get_physics_config"):
        var current_physics_config = _motion_system.get_physics_config()
        if current_physics_config:
            # Use 'in' to check for property existence on Resource objects
            if "default_launch_angle_degrees" in current_physics_config:
                current_angle = current_physics_config.default_launch_angle_degrees
            if "default_launch_strength" in current_physics_config:
                current_strength = current_physics_config.default_launch_strength
    
    _entity_data[entity_id] = {
        "launch_power": 1.0,
        "launch_angle_degrees": current_angle,
        "launch_strength": current_strength,
        "last_launch_vector": Vector2.ZERO,
        "last_launch_time": 0.0
    }
    return true

# Unregister an entity from the launch system
# entity_id: Unique identifier for the entity
# Returns: True if unregistration was successful
func unregister_entity(entity_id: int) -> bool:
    if not _entity_data.has(entity_id):
        return false
    
    _entity_data.erase(entity_id)
    return true

# Set launch parameters for an entity
# entity_id: Unique identifier for the entity
# angle_degrees: Launch angle in degrees (0-90)
# power: Launch power (0.0-1.0)
# strength: Base magnitude of the launch force
# Returns: True if parameters were set successfully
func set_launch_parameters(entity_id: int, angle_degrees: float, power: float, strength: float = -1.0) -> bool:
    if not _entity_data.has(entity_id):
        if not register_entity(entity_id):
            return false
    
    var launch_data = _entity_data[entity_id]
    launch_data.launch_angle_degrees = clamp(angle_degrees, 0, 90)
    launch_data.launch_power = clamp(power, 0.1, 1.0)
    
    if strength > 0:
        launch_data.launch_strength = strength
    
    return true

# Update the last launch vector for an entity
# entity_id: Unique identifier for the entity
# launch_vector: The launch vector to store
func update_launch_vector(entity_id: int, launch_vector: Vector2) -> void:
    if not _entity_data.has(entity_id):
        return
    
    _entity_data[entity_id].last_launch_vector = launch_vector
    _entity_data[entity_id].last_launch_time = Time.get_ticks_msec() / 1000.0

# Get the data for an entity
# entity_id: Unique identifier for the entity
# Returns: The entity data, or an empty dictionary if not found
func get_data(entity_id: int) -> Dictionary:
    if not _entity_data.has(entity_id):
        ErrorHandler.warning("LaunchEntityData", "Entity not registered: " + str(entity_id))
        return {}
    
    return _entity_data[entity_id]

# Get the last launch vector for an entity
# entity_id: Unique identifier for the entity
# Returns: The last launch vector, or Vector2.ZERO if not found
func get_last_launch_vector(entity_id: int) -> Vector2:
    if not _entity_data.has(entity_id):
        return Vector2.ZERO
    
    return _entity_data[entity_id].last_launch_vector

# Check if an entity is registered
# entity_id: Unique identifier for the entity
# Returns: True if the entity is registered
func has_entity(entity_id: int) -> bool:
    return _entity_data.has(entity_id)
