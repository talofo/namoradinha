class_name PhysicsConfig
extends Resource

# Basic physics parameters
@export var gravity: float = 980.0
@export var default_ground_friction: float = 0.1  # Lower value means longer slides
@export var default_stop_threshold: float = 0.1  # Lower value means player will slide longer before stopping

# Bounce physics
@export var first_bounce_ratio: float = 0.9  # First bounce height relative to max launch height (higher = higher bounces)
@export var subsequent_bounce_ratio: float = 0.8  # Subsequent bounce height relative to previous (higher = more bounces)
@export var min_bounce_height_threshold: float = 20.0  # Minimum height for a bounce to occur (lower = more bounces)
@export var max_bounce_count: int = 15  # Maximum number of bounces allowed, regardless of height
@export var min_slide_speed: float = 150.0  # Minimum speed for sliding (lower = slides start at lower speeds)
@export var horizontal_preservation: float = 0.98  # How much horizontal velocity is preserved per bounce (higher = longer slides)
@export var min_bounce_energy_ratio: float = 0.7  # Minimum ratio of normal velocity to maintain after bounce (higher = more energetic bounces)
@export var min_bounce_kinetic_energy: float = 2000.0  # Minimum kinetic energy required to continue bouncing (lower = more bounces)
@export var min_stop_speed: float = 5.0  # Minimum speed below which the entity transitions from sliding to stopped (lower = longer slides)

# Sliding physics 
@export var deceleration_base: float = 0.1  # Base deceleration factor (lower = slower deceleration)
@export var deceleration_speed_factor: float = 0.0003  # How much speed affects deceleration (lower = less speed-based deceleration)
@export var max_deceleration_factor: float = 0.15  # Maximum deceleration per frame (lower = gentler deceleration cap)
@export var frame_rate_adjustment: float = 60.0  # Base frame rate for physics calculations

# Launch physics
@export var default_launch_strength: float = 1500.0
@export var default_launch_angle_degrees: float = 45.0

# Boost physics (from ManualAirBoost)
@export var manual_air_boost_rising_strength: float = 300.0
@export var manual_air_boost_rising_angle: float = 45.0
@export var manual_air_boost_falling_strength: float = 800.0  # Higher value = stronger downward boost = higher next bounce
@export var manual_air_boost_falling_angle: float = -60.0

# Material properties (from CollisionMaterialSystem)
@export var default_material_friction: float = 0.3
@export var default_material_bounce: float = 0.8  # Higher value = bouncier surfaces
@export var ice_material_friction: float = 0.05  # Very low friction for ice
@export var ice_material_bounce: float = 0.9  # Very bouncy ice
@export var mud_material_friction: float = 1.5  # High friction for mud
@export var mud_material_bounce: float = 0.3  # Low bounce for mud
@export var rubber_material_friction: float = 1.0
@export var rubber_material_bounce: float = 0.95  # Very bouncy rubber

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
