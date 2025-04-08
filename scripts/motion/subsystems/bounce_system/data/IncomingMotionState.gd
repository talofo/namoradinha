class_name IncomingMotionState
extends RefCounted

## Holds the player's motion state immediately before impact calculation.

# The player's velocity vector at the moment of impact.
var velocity: Vector2 = Vector2.ZERO

# The player's mass (may influence interactions, though not directly used in basic bounce).
var mass: float = 1.0

# The current gravity scale affecting the player (e.g., 1.0 for normal, <1 for reduced gravity).
# This allows dynamic effects (like gravity fields) to influence the bounce calculation indirectly.
var gravity_scale: float = 1.0

func _init(p_velocity: Vector2 = Vector2.ZERO, p_mass: float = 1.0, p_gravity_scale: float = 1.0) -> void:
	velocity = p_velocity
	mass = p_mass
	gravity_scale = p_gravity_scale
