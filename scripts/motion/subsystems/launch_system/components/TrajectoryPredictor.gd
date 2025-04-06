class_name TrajectoryPredictor
extends RefCounted

# Reference to motion system for config access
var _motion_system = null

func set_motion_system(motion_system) -> void:
    _motion_system = motion_system

# Generate trajectory preview points
# entity_data: Dictionary containing launch parameters
# num_points: Number of points to generate
# time_step: Time step between points
# Returns: Array of Vector2 points representing the trajectory
func calculate_trajectory(entity_data: Dictionary, num_points: int = 20, time_step: float = 0.1) -> Array:
    if entity_data.is_empty():
        ErrorHandler.warning("TrajectoryPredictor", "Empty entity data provided")
        return []
    
    var points = []
    
    # Calculate initial velocity
    var angle_radians = deg_to_rad(entity_data.launch_angle_degrees)
    var initial_velocity = Vector2(
        cos(angle_radians) * entity_data.launch_strength * entity_data.launch_power,
        -sin(angle_radians) * entity_data.launch_strength * entity_data.launch_power
    )
    
    # Ensure motion system and config are available
    if not _motion_system or not _motion_system.has_method("get_physics_config"):
        ErrorHandler.error("TrajectoryPredictor", "MotionSystem or get_physics_config method not available.")
        return []
    var current_physics_config = _motion_system.get_physics_config()
    if not current_physics_config:
        ErrorHandler.error("TrajectoryPredictor", "Physics config not available from MotionSystem.")
        return []
        
    # Get gravity from config
    var gravity = current_physics_config.get_gravity_for_entity("default", 1.0)
    
    # Simple physics simulation to get trajectory points
    var pos = Vector2.ZERO
    var vel = initial_velocity
    
    for i in range(num_points):
        points.append(pos)
        vel.y += gravity * time_step
        pos += vel * time_step
        
        # Optional: Stop if we hit the ground (y > 0)
        # This assumes the ground is at y=0, adjust as needed
        if pos.y > 0:
            points.append(Vector2(pos.x, 0))
            break
    
    return points
