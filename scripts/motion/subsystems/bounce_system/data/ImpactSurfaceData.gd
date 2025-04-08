class_name ImpactSurfaceData
extends RefCounted

## Holds information about the surface involved in the collision.

# The surface normal vector at the point of impact. Points away from the surface.
var normal: Vector2 = Vector2.UP # Default to flat ground normal

# The exact point of collision in global coordinates.
var collision_point: Vector2 = Vector2.ZERO

# The elasticity (bounciness) of the surface. Typically 0.0 to 1.0.
# 0.0 = No bounce (absorbs all perpendicular velocity).
# 1.0 = Perfect bounce (reflects all perpendicular velocity).
var elasticity: float = 0.5 # Example default

# The kinetic friction coefficient of the surface. Typically >= 0.0.
# Affects sliding/stopping parallel to the surface.
var friction: float = 0.1 # Example default

# The slope angle of the surface in radians (optional, could be derived from normal).
# Might be useful for specific slope-based mechanics.
var slope_angle: float = 0.0

func _init(p_normal: Vector2 = Vector2.UP, p_collision_point: Vector2 = Vector2.ZERO, p_elasticity: float = 0.5, p_friction: float = 0.1) -> void:
	normal = p_normal
	collision_point = p_collision_point
	elasticity = p_elasticity
	friction = p_friction
	# Calculate slope angle from normal if needed, or expect it to be set externally
	if normal.is_normalized() and normal != Vector2.UP:
		slope_angle = Vector2.RIGHT.angle_to(normal.orthogonal()) # Angle relative to horizontal
	else:
		slope_angle = 0.0
