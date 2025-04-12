class_name PhysicsConfig
extends Resource

# Basic physics parameters
@export var gravity: float = 1200.0
@export var default_ground_friction: float = 0.15  # Middle ground between original 0.2 and our 0.1
@export var default_stop_threshold: float = 0.5

# Bounce physics
@export var first_bounce_ratio: float = 0.8  # First bounce height relative to max launch height
@export var subsequent_bounce_ratio: float = 0.6  # Subsequent bounce height relative to previous
@export var min_bounce_height_threshold: float = 5.0  # Minimum height for a bounce to occur
@export var max_bounce_count: int = 10  # Maximum number of bounces allowed, regardless of height
@export var min_slide_speed: float = 200.0  # Minimum speed for sliding
@export var horizontal_preservation: float = 0.95  # How much horizontal velocity is preserved per bounce

# Sliding physics 
@export var deceleration_base: float = 0.1  # Base deceleration factor
@export var deceleration_speed_factor: float = 0.0005  # How much speed affects deceleration
@export var max_deceleration_factor: float = 0.15  # Maximum deceleration per frame
@export var frame_rate_adjustment: float = 60.0  # Base frame rate for physics calculations

# Launch physics
@export var default_launch_strength: float = 1500.0
@export var default_launch_angle_degrees: float = 45.0

# Entity specific defaults
@export var default_mass: float = 1.0
@export var default_size_factor: float = 1.0

# Override parameters for specific entity types
# Format: { "entity_type": { "param_name": value } }
@export var entity_overrides: Dictionary = {}

# Get a parameter value for a specific entity
func get_param(param_name: String, entity_type: String = "default") -> Variant:
    # Check if we have overrides for this entity type
    if entity_overrides.has(entity_type) and entity_overrides[entity_type].has(param_name):
        return entity_overrides[entity_type][param_name]
    
    # Otherwise return the default value
    if has_method("get_" + param_name):
        return call("get_" + param_name)
    
    # Fallback to property access
    return get(param_name)

# Calculate gravity for a specific entity
func get_gravity_for_entity(entity_type: String, mass: float = 1.0) -> float:
    var base_gravity = get_param("gravity", entity_type)
    return base_gravity * mass
