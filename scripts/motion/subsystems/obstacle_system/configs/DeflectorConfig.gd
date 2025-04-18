# scripts/motion/subsystems/obstacle_system/configs/DeflectorConfig.gd
# Configuration resource for the Deflector obstacle type.
class_name DeflectorConfig
extends Resource

# The angle in degrees to deflect the entity's trajectory
@export var deflect_angle: float = 15.0

# Random variance to apply to the deflection angle (in degrees)
@export var angle_variance: float = 5.0

# The direction that triggers the deflection (top, bottom, left, right, any)
@export var trigger_direction: String = "top"
