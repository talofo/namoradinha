# scripts/motion/subsystems/obstacle_system/configs/WeakenerConfig.gd
# Configuration resource for the Weakener obstacle type.
class_name WeakenerConfig
extends Resource

# The multiplier to apply to the entity's velocity (0.0 to 1.0)
@export var velocity_multiplier: float = 0.6

# Whether to apply the multiplier to the X component of velocity
@export var apply_to_x: bool = true

# Whether to apply the multiplier to the Y component of velocity
@export var apply_to_y: bool = true
