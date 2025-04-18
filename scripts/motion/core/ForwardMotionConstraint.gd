class_name ForwardMotionConstraint
extends Object

static func enforce(velocity: Vector2, enforce_flag: bool) -> Vector2:
	# If enforcement is enabled and velocity.x is negative, clamp to zero
	if enforce_flag and velocity.x < 0.0:
		return Vector2(0.0, velocity.y)
	return velocity
