# scripts/motion/subsystems/boost_system/interfaces/IBoostType.gd
# Interface that all boost type implementations must follow.
class_name IBoostType
extends RefCounted

const BoostContext = preload("res://scripts/motion/subsystems/boost_system/data/BoostContext.gd")

# Check if the boost can be applied in the current context.
# boost_context: A BoostContext object containing current state.
# Returns: True if the boost can be applied, false otherwise.
func can_apply_boost(boost_context: BoostContext) -> bool:
	push_error("IBoostType.can_apply_boost() must be implemented by subclasses")
	return false

# Calculate the boost vector to apply based on the context.
# boost_context: A BoostContext object containing current state.
# Returns: A Vector2 representing the velocity change to apply.
#          Should return Vector2.ZERO if the boost calculation results in no change.
func calculate_boost_vector(boost_context: BoostContext) -> Vector2:
	push_error("IBoostType.calculate_boost_vector() must be implemented by subclasses")
	return Vector2.ZERO
