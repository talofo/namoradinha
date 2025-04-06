class_name BounceCalculator
extends RefCounted

# Reference to motion system for config access
var _motion_system = null

func set_motion_system(motion_system) -> void:
    _motion_system = motion_system

# Calculate the bounce vector for an entity
# entity_data: Dictionary containing bounce data
# collision_info: Information about the collision
# Returns: The bounce vector
func calculate_bounce_vector(entity_data: Dictionary, collision_info: Dictionary) -> Vector2:
    if entity_data.is_empty():
        ErrorHandler.warning("BounceCalculator", "Empty entity data provided")
        return Vector2.ZERO
    
    # Get entity properties
    var entity_type = collision_info.get("entity_type", "default")
    var entity_mass = collision_info.get("mass", 1.0) # Default to 1.0 if not specified
    
    # Ensure motion system and config are available
    if not _motion_system or not _motion_system.has_method("get_physics_config"):
        ErrorHandler.error("BounceCalculator", "MotionSystem or get_physics_config method not available.")
        return Vector2.ZERO
    var current_physics_config = _motion_system.get_physics_config()
    if not current_physics_config:
        ErrorHandler.error("BounceCalculator", "Physics config not available from MotionSystem.")
        return Vector2.ZERO
        
    # Get gravity from config
    var gravity = current_physics_config.get_gravity_for_entity(entity_type, entity_mass)
        
    # Calculate the max height achieved relative to floor
    # Important: This calculation should always result in a positive value
    var max_height_reached = entity_data.floor_position_y - entity_data.max_height_y
    
    # Debug the height calculation
    ErrorHandler.debug("BounceCalculator", "Bounce #" + str(entity_data.bounce_count) + 
          " floor_position_y=" + str(entity_data.floor_position_y) + 
          " max_height_y=" + str(entity_data.max_height_y) + 
          " calculated max_height_reached=" + str(max_height_reached))
    
    # Ensure we have a sensible positive value even if position tracking had issues
    if max_height_reached <= 10:
        # If tracking gave us invalid height, use the magnitude of the original launch Y velocity
        # to estimate how high the player would have gone using basic physics formula: h = v²/2g
        var launch_velocity_y_magnitude = abs(entity_data.launch_velocity.y)
        max_height_reached = (launch_velocity_y_magnitude * launch_velocity_y_magnitude) / (2 * gravity)
        ErrorHandler.debug("BounceCalculator", "Using velocity-based height estimate instead: " + str(max_height_reached))
    
    # Calculate bounce based on height reached using config values
    var current_first_bounce_ratio = current_physics_config.first_bounce_ratio
    var current_subsequent_bounce_ratio = current_physics_config.subsequent_bounce_ratio
    var current_min_bounce_height_threshold = current_physics_config.min_bounce_height_threshold
    
    # Calculate target height for this bounce
    var target_height = 0.0
    
    # Get max bounce count from physics config
    var max_bounce_count = current_physics_config.max_bounce_count
    
    if entity_data.bounce_count == 0:
        # First bounce - relative to max launch height
        target_height = max_height_reached * current_first_bounce_ratio
        ErrorHandler.debug("BounceCalculator", "First bounce calculation: max_height_reached=" + str(max_height_reached) + 
            " * first_bounce_ratio=" + str(current_first_bounce_ratio) + " = target_height=" + str(target_height))
    else:
        # Calculate theoretical target height using exponential decay
        # For subsequent bounces, we use the previous bounce's target height
        target_height = entity_data.current_target_height * current_subsequent_bounce_ratio
        
        # Calculate theoretical max bounces based on physics parameters
        var theoretical_max_bounces = _calculate_theoretical_max_bounces(
            max_height_reached, 
            current_first_bounce_ratio, 
            current_subsequent_bounce_ratio, 
            current_min_bounce_height_threshold
        )
        
        # Use the smaller of the two max bounce values
        var effective_max_bounces = min(theoretical_max_bounces, max_bounce_count)
        
        ErrorHandler.debug("BounceCalculator", "Bounce limits - theoretical_max_bounces=" + str(theoretical_max_bounces) + 
            ", config_max_bounces=" + str(max_bounce_count) + 
            ", effective_max_bounces=" + str(effective_max_bounces))
        
        # If we're approaching the max bounce count, force the target height below threshold
        if entity_data.bounce_count >= effective_max_bounces - 1:
            target_height = current_min_bounce_height_threshold * 0.5  # Force below threshold
            ErrorHandler.info("BounceCalculator", "Reached max bounce count (" + str(effective_max_bounces) + 
                "), forcing target height below threshold: " + str(target_height))
        
        ErrorHandler.debug("BounceCalculator", "Subsequent bounce calculation: previous_target_height=" + 
            str(entity_data.current_target_height) + " * subsequent_bounce_ratio=" + 
            str(current_subsequent_bounce_ratio) + " = target_height=" + str(target_height))
    
    # Calculate required velocity to reach that height
    # Using physics formula: v = sqrt(2 * g * h)
    var bounce_velocity_y = 0.0
    
    # Use ORIGINAL launch velocity for horizontal momentum, with consistent reduction based on bounce count
    # This prevents the horizontal velocity from increasing with each bounce
    var current_horizontal_preservation = current_physics_config.horizontal_preservation
    current_horizontal_preservation = pow(current_horizontal_preservation, entity_data.bounce_count)  # reduction per bounce
    var bounce_velocity_x = entity_data.launch_velocity.x * current_horizontal_preservation

    ErrorHandler.debug("BounceCalculator", "target_height=" + str(target_height) + " bounce_count=" + str(entity_data.bounce_count))

    # We already have current_min_bounce_height_threshold from earlier
    
    ErrorHandler.info("BounceCalculator", "Bounce decision - bounce_count=" + str(entity_data.bounce_count) + 
        ", target_height=" + str(target_height) + 
        ", min_bounce_height_threshold=" + str(current_min_bounce_height_threshold))
    
    # Continue bouncing if the target height is above the minimum threshold
    if target_height >= current_min_bounce_height_threshold:
        bounce_velocity_y = -sqrt(2 * gravity * target_height)
        ErrorHandler.info("BounceCalculator", "Continuing to bounce with velocity_y=" + str(bounce_velocity_y) + 
            " for bounce #" + str(entity_data.bounce_count + 1))
    else:
        # No more energy for bouncing - stop and start sliding
        bounce_velocity_y = 0.0  # Ensure y velocity is exactly zero for sliding
        
        # Keep the correctly calculated horizontal velocity (original launch X reduced by preservation factor over bounces)
        # No minimum speed enforcement or boosts applied here.
        # bounce_velocity_x is already calculated correctly above based on launch_velocity and preservation.
        ErrorHandler.info("BounceCalculator", "Stopping bounce after " + str(entity_data.bounce_count) + 
            " bounces, target_height=" + str(target_height) + 
            ", transitioning to slide with velocity_x=" + str(bounce_velocity_x))
    
    var bounce_vector = Vector2(bounce_velocity_x, bounce_velocity_y)
    ErrorHandler.debug("BounceCalculator", "Final bounce vector=" + str(bounce_vector))
    
    return bounce_vector

# Check if an entity should stop bouncing
# entity_data: Dictionary containing bounce data
# Returns: True if the entity should stop bouncing
func should_stop_bouncing(entity_data: Dictionary) -> bool:
    if entity_data.is_empty():
        ErrorHandler.debug("BounceCalculator", "should_stop_bouncing: Entity data is empty, stopping bounce")
        return true
    
    # Ensure motion system and config are available
    if not _motion_system or not _motion_system.has_method("get_physics_config"):
        ErrorHandler.error("BounceCalculator", "MotionSystem or get_physics_config method not available.")
        return true # Assume stop if config is missing
    var current_physics_config = _motion_system.get_physics_config()
    if not current_physics_config:
        ErrorHandler.error("BounceCalculator", "Physics config not available from MotionSystem.")
        return true # Assume stop if config is missing
    
    # Calculate the max height achieved relative to floor
    var max_height_reached = entity_data.floor_position_y - entity_data.max_height_y
    
    # Ensure we have a sensible positive value
    if max_height_reached <= 10:
        # Use the magnitude of the original launch Y velocity to estimate height
        var gravity = current_physics_config.get_gravity_for_entity("default", 1.0)
        var launch_velocity_y_magnitude = abs(entity_data.launch_velocity.y)
        max_height_reached = (launch_velocity_y_magnitude * launch_velocity_y_magnitude) / (2 * gravity)
    
    # Get physics config parameters
    var current_first_bounce_ratio = current_physics_config.first_bounce_ratio
    var current_subsequent_bounce_ratio = current_physics_config.subsequent_bounce_ratio
    var current_min_bounce_height_threshold = current_physics_config.min_bounce_height_threshold
    var max_bounce_count = current_physics_config.max_bounce_count
    
    # Calculate target height using the same logic as in calculate_bounce_vector
    var target_height = 0.0
    
    if entity_data.bounce_count == 0:
        target_height = max_height_reached * current_first_bounce_ratio
    else:
        # Use the same exponential decay as in calculate_bounce_vector
        target_height = entity_data.current_target_height * current_subsequent_bounce_ratio
        
        # Calculate theoretical max bounces
        var theoretical_max_bounces = _calculate_theoretical_max_bounces(
            max_height_reached, 
            current_first_bounce_ratio, 
            current_subsequent_bounce_ratio, 
            current_min_bounce_height_threshold
        )
        
        # Use the smaller of the two max bounce values
        var effective_max_bounces = min(theoretical_max_bounces, max_bounce_count)
        
        # If we're at or beyond the max bounce count, force stop
        if entity_data.bounce_count >= effective_max_bounces:
            return true
    
    # We already have current_min_bounce_height_threshold from earlier
    
    var should_stop = target_height < current_min_bounce_height_threshold
    ErrorHandler.debug("BounceCalculator", "should_stop_bouncing: target_height=" + str(target_height) + 
        " min_bounce_height_threshold=" + str(current_min_bounce_height_threshold) + 
        " bounce_count=" + str(entity_data.bounce_count) + 
        " should_stop=" + str(should_stop))
    
    return should_stop

# Calculate the theoretical maximum number of bounces based on physics parameters
# max_height: The maximum height reached
# first_bounce_ratio: The ratio for the first bounce
# subsequent_bounce_ratio: The ratio for subsequent bounces
# min_bounce_height_threshold: The minimum height threshold for a bounce to occur
# Returns: The theoretical maximum number of bounces
func _calculate_theoretical_max_bounces(max_height: float, first_bounce_ratio: float, subsequent_bounce_ratio: float, min_bounce_height_threshold: float) -> int:
    # Calculate the height of the first bounce
    var first_bounce_height = max_height * first_bounce_ratio
    
    # If the first bounce is already below the threshold, return 0
    if first_bounce_height < min_bounce_height_threshold:
        return 0
    
    # Calculate how many bounces it would take for the height to fall below the threshold
    # Using the formula: min_threshold = first_bounce_height * (subsequent_bounce_ratio^(n-1))
    # Solving for n: n = 1 + log(min_threshold / first_bounce_height) / log(subsequent_bounce_ratio)
    var n = 1.0
    if subsequent_bounce_ratio > 0 and subsequent_bounce_ratio < 1:
        n += log(min_bounce_height_threshold / first_bounce_height) / log(subsequent_bounce_ratio)
    
    # Round down to get the integer number of bounces
    # Add 1 to account for the first bounce
    return max(1, int(n))

# Check if a collision is with the floor
# collision_info: Information about the collision
# Returns: True if the collision is with the floor
func is_floor_collision(collision_info: Dictionary) -> bool:
    var normal = collision_info.get("normal", Vector2.ZERO)
    return normal.y < -0.7  # Consider surfaces with normals pointing mostly up as floors
