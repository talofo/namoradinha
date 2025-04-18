class_name PhysicsConfig
extends Resource

# Basic physics parameters
@export var gravity: float = 980.0  # Base gravity value used throughout the physics system
@export var default_ground_friction: float = 0.1  # Base friction for ground surfaces (lower = longer slides)
@export var default_stop_threshold: float = 0.1  # Speed threshold for stopping sliding motion (lower = longer slides)

# Bounce physics
# NOTE: first_bounce_ratio and subsequent_bounce_ratio are currently unused
# The bounce behavior is controlled by effective_elasticity (surface.elasticity * profile.bounciness_multiplier)
@export var first_bounce_ratio: float = 0.9  # UNUSED: First bounce height relative to max launch height
@export var subsequent_bounce_ratio: float = 0.8  # UNUSED: Subsequent bounce height relative to previous

@export var min_bounce_height_threshold: float = 75.0  # Minimum height for a bounce to continue (lower = more bounces)
@export var min_slide_speed: float = 150.0  # Minimum horizontal speed required to enter sliding state
@export var horizontal_preservation: float = 0.98  # Multiplier for horizontal velocity preservation per bounce
@export var min_bounce_energy_ratio: float = 0.7  # Minimum ratio of energy to preserve in bounce calculations
@export var min_bounce_kinetic_energy: float = 5000.0  # Minimum kinetic energy to continue bouncing
@export var min_stop_speed: float = 10.0  # Speed threshold to transition from sliding to stopped

# Sliding physics 
@export var deceleration_base: float = 0.1  # Base deceleration factor for sliding
@export var deceleration_speed_factor: float = 0.0003  # How much speed affects deceleration rate
@export var max_deceleration_factor: float = 0.15  # Maximum deceleration factor per frame
@export var frame_rate_adjustment: float = 60.0  # Target frame rate for physics calculations

# Launch physics
@export var default_launch_strength: float = 1500.0  # Base strength for entity launches
@export var default_launch_angle_degrees: float = 45.0  # Default angle for entity launches (in degrees)

# Boost physics (used by AirBoostType)
@export var manual_air_boost_rising_strength: float = 300.0  # Strength of boost when rising
@export var manual_air_boost_rising_angle: float = 45.0  # Angle of boost when rising (degrees)
@export var manual_air_boost_falling_strength: float = 800.0  # Strength of boost when falling
@export var manual_air_boost_falling_angle: float = -60.0  # Angle of boost when falling (degrees)

# Material properties (used by CollisionMaterialSystem)
@export var default_material_friction: float = 0.3  # Default friction for surfaces
@export var default_material_bounce: float = 0.8  # Default bounciness for surfaces
@export var ice_material_friction: float = 0.05  # Friction for ice surfaces
@export var ice_material_bounce: float = 0.9  # Bounciness for ice surfaces
@export var mud_material_friction: float = 1.5  # Friction for mud surfaces
@export var mud_material_bounce: float = 0.3  # Bounciness for mud surfaces
@export var rubber_material_friction: float = 1.0  # Friction for rubber surfaces
@export var rubber_material_bounce: float = 0.95  # Bounciness for rubber surfaces

# Entity specific defaults
@export var default_mass: float = 1.0  # Default mass for physics entities
@export var default_size_factor: float = 1.0  # Default size scaling factor (currently unused)

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
