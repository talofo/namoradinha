class_name BoostCalculator
extends RefCounted

# Reference to motion system for config access
var _motion_system = null

func set_motion_system(motion_system) -> void:
    _motion_system = motion_system
    # Logging removed

# Calculate the combined boost vector for an entity
# entity_data: Dictionary containing boost data for the entity
# Returns: The combined boost vector
func calculate_boost_vector(entity_data: Dictionary) -> Vector2:
    if entity_data.is_empty() or not entity_data.has("active_boosts") or entity_data.active_boosts.is_empty():
        return Vector2.ZERO
    
    var combined_vector = Vector2.ZERO
    
    # Combine all active boosts
    for boost in entity_data.active_boosts:
        var boost_vector = boost.direction.normalized() * boost.strength
        combined_vector += boost_vector
    
    # Logging removed - active boosts count
    
    return combined_vector

# Calculate a boost vector for a specific boost
# boost: Dictionary containing boost data
# Returns: The boost vector
func calculate_single_boost_vector(boost: Dictionary) -> Vector2:
    if boost.is_empty() or not boost.has("direction") or not boost.has("strength"):
        # Logging removed
        return Vector2.ZERO
    
    var boost_vector = boost.direction.normalized() * boost.strength
    
    # Logging removed for boost with direction and strength
    
    return boost_vector

# Calculate a boost vector with physics config adjustments
# entity_data: Dictionary containing boost data for the entity
# entity_type: Type of entity (e.g., "player", "enemy")
# entity_mass: Mass of the entity
# Returns: The adjusted boost vector
func calculate_adjusted_boost_vector(entity_data: Dictionary, entity_type: String = "default", entity_mass: float = 1.0) -> Vector2:
    var base_vector = calculate_boost_vector(entity_data)
    
    # If no boosts or no motion system, return the base vector
    if base_vector == Vector2.ZERO or not _motion_system:
        return base_vector
    
    # Get physics config for adjustments
    var physics_config = _motion_system.get_physics_config()
    if not physics_config:
        # Logging removed
        return base_vector
    
    # Apply mass-based adjustment (heavier entities get less boost)
    var mass_factor = 1.0 / max(entity_mass, 0.1)  # Prevent division by zero
    
    # Apply entity type-specific adjustments
    var type_factor = 1.0
    if entity_type == "player":
        type_factor = physics_config.get("player_boost_factor", 1.0)
    elif entity_type == "enemy":
        type_factor = physics_config.get("enemy_boost_factor", 0.8)
    
    # Apply the adjustments
    var adjusted_vector = base_vector * mass_factor * type_factor
    
    # Logging removed - adjusted vector details
    
    return adjusted_vector

# Calculate the remaining boost duration
# boost: Dictionary containing boost data
# Returns: The remaining duration in seconds, or -1 for permanent boosts
func calculate_remaining_duration(boost: Dictionary) -> float:
    if boost.is_empty() or not boost.has("duration") or not boost.has("remaining_time"):
        # Logging removed
        return 0.0
    
    # Permanent boosts
    if boost.duration < 0:
        return -1.0
    
    return max(0.0, boost.remaining_time)

# Calculate the boost effectiveness based on conditions
# boost: Dictionary containing boost data
# velocity: Current velocity of the entity
# Returns: A factor (0.0 to 1.0) representing effectiveness
func calculate_boost_effectiveness(boost: Dictionary, velocity: Vector2) -> float:
    if boost.is_empty() or not boost.has("direction"):
        # Logging removed
        return 0.0
    
    # Base effectiveness
    var effectiveness = 1.0
    
    # Reduce effectiveness if boosting against current movement
    var angle = velocity.angle_to(boost.direction)
    if abs(angle) > PI/2:  # More than 90 degrees
        var opposition_factor = abs(angle) / PI  # 0.5 to 1.0
        effectiveness *= (1.0 - opposition_factor * 0.5)  # Reduce by up to 50%
    
    # Reduce effectiveness at high speeds
    var speed = velocity.length()
    var speed_threshold = 500.0  # Example threshold
    if speed > speed_threshold:
        var speed_factor = min(1.0, speed_threshold / speed)
        effectiveness *= speed_factor
    
    # Logging removed - boost effectiveness details
    
    return effectiveness
