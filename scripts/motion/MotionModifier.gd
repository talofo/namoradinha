class_name MotionModifier
extends Resource

# Source system that generated this modifier
var source: String

# Type of modification (e.g., "velocity", "gravity", "friction")
var type: String

# Priority level for conflict resolution (higher = more important)
var priority: int = 0

# How long this modifier lasts (-1 for permanent)
var duration: float = -1

# The actual motion vector modification
var vector: Vector2 = Vector2.ZERO

# For scalar modifications (e.g., friction multiplier)
var scalar: float = 1.0

# Whether this adds to or replaces existing motion
var is_additive: bool = true

func _init(p_source: String = "", p_type: String = "", p_priority: int = 0, 
		p_vector: Vector2 = Vector2.ZERO, p_scalar: float = 1.0, 
		p_is_additive: bool = true, p_duration: float = -1) -> void:
	source = p_source
	type = p_type
	priority = p_priority
	vector = p_vector
	scalar = p_scalar
	is_additive = p_is_additive
	duration = p_duration

# String representation for debugging
func _to_string() -> String:
	return "[MotionModifier] Source: %s, Type: %s, Priority: %d, Vector: %s, Scalar: %.2f, Additive: %s, Duration: %.1f" % [
		source, type, priority, vector, scalar, str(is_additive), duration
	]
