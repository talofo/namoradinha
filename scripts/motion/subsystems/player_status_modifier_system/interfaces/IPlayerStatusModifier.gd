# scripts/motion/subsystems/player_status_modifier_system/interfaces/IPlayerStatusModifier.gd
# Interface for player status modifier types.
class_name IPlayerStatusModifier
extends RefCounted

# Apply the modifier and return modifiers
# entity_id: The ID of the entity to apply the modifier to
# strength: The strength of the modifier (0.0 to 1.0)
# duration: The duration of the modifier in seconds
# Returns: Array of MotionModifier objects
func apply(_entity_id: String, _strength: float, _duration: float) -> Array:
	push_error("IPlayerStatusModifier.apply() is not implemented")
	return []
