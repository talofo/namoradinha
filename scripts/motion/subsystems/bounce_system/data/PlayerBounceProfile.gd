class_name PlayerBounceProfile
extends RefCounted

## Encapsulates permanent player-specific modifiers affecting bounce behavior.
## These values are typically derived from character traits, equipment, class, etc.

# Multiplier applied to the surface elasticity. > 1.0 increases bounciness, < 1.0 decreases it.
var bounciness_multiplier: float = 1.0

# Additive adjustment to the calculated bounce angle (in radians).
# Positive values might angle the bounce more upwards/forwards depending on convention.
# NOTE: Currently unused with flat ground, but preserved for future implementation with sloped surfaces.
var bounce_angle_adjustment: float = 0.0

# Multiplier applied to the effective gravity during bounce calculation.
# Allows traits/equipment to make the player feel lighter or heavier during bounces.
# NOTE: Currently unused in bounce calculation, but preserved for future implementation.
var gravity_scale_modifier: float = 1.0

# Multiplier affecting how surface friction is applied during the bounce/slide transition.
# > 1.0 increases friction effect, < 1.0 decreases it.
var friction_interaction_modifier: float = 1.0

# Multiplier applied to the horizontal component of the bounce velocity.
var horizontal_speed_modifier: float = 1.0

# Multiplier applied to the vertical component of the bounce velocity.
var vertical_speed_modifier: float = 1.0

# Add other relevant permanent modifiers as needed based on game design.

func _init(
	p_bounciness_multiplier: float = 1.0,
	p_bounce_angle_adjustment: float = 0.0,
	p_gravity_scale_modifier: float = 1.0,
	p_friction_interaction_modifier: float = 1.0,
	p_horizontal_speed_modifier: float = 1.0,
	p_vertical_speed_modifier: float = 1.0
) -> void:
	bounciness_multiplier = p_bounciness_multiplier
	bounce_angle_adjustment = p_bounce_angle_adjustment
	gravity_scale_modifier = p_gravity_scale_modifier
	friction_interaction_modifier = p_friction_interaction_modifier
	horizontal_speed_modifier = p_horizontal_speed_modifier
	vertical_speed_modifier = p_vertical_speed_modifier
