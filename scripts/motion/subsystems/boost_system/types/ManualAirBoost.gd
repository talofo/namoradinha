# scripts/motion/subsystems/boost_system/types/ManualAirBoost.gd
# Implementation for the Manual Air Boost type.
# This class implements the IBoostType interface by providing the required methods:
# - can_apply_boost(boost_context)
# - calculate_boost_vector(boost_context)
class_name ManualAirBoost
extends RefCounted

# Explicitly preload dependencies
const IBoostType = preload("res://scripts/motion/subsystems/boost_system/interfaces/IBoostType.gd")
const BoostContext = preload("res://scripts/motion/subsystems/boost_system/data/BoostContext.gd")

# Default values - these could be loaded from configuration or overridden by physics_config
const DEFAULT_RISING_BOOST_STRENGTH = 300.0
const DEFAULT_FALLING_BOOST_STRENGTH = 500.0
const DEFAULT_RISING_BOOST_ANGLE = 45.0  # Degrees upward from horizontal
const DEFAULT_FALLING_BOOST_ANGLE = -60.0 # Degrees downward from horizontal

# Future enhancement point: Add apex detection if needed
# const APEX_VELOCITY_THRESHOLD = 10.0

# Check if the boost can be applied in the current context.
func can_apply_boost(boost_context: BoostContext) -> bool:
	# Manual air boosts can only be applied when airborne
	return boost_context.is_airborne

# Calculate the boost vector to apply based on the context.
func calculate_boost_vector(boost_context: BoostContext) -> Vector2:
	var physics_config = boost_context.physics_config
	var boost_strength = 0.0
	var boost_angle_degrees = 0.0

	# Simple approach: Treat based on is_rising flag
	# Future enhancement point: Add special apex handling here if needed
	if boost_context.is_rising:
		boost_strength = DEFAULT_RISING_BOOST_STRENGTH
		boost_angle_degrees = DEFAULT_RISING_BOOST_ANGLE

		# Use physics config if available and property exists
		if physics_config and physics_config.has("manual_air_boost_rising_strength"):
			boost_strength = physics_config.manual_air_boost_rising_strength
		if physics_config and physics_config.has("manual_air_boost_rising_angle"):
			boost_angle_degrees = physics_config.manual_air_boost_rising_angle
	else:
		# Falling (and apex, using the simpler approach)
		boost_strength = DEFAULT_FALLING_BOOST_STRENGTH
		boost_angle_degrees = DEFAULT_FALLING_BOOST_ANGLE

		# Use physics config if available and property exists
		if physics_config and physics_config.has("manual_air_boost_falling_strength"):
			boost_strength = physics_config.manual_air_boost_falling_strength
		if physics_config and physics_config.has("manual_air_boost_falling_angle"):
			boost_angle_degrees = physics_config.manual_air_boost_falling_angle

	# Convert angle to radians for trigonometric functions
	var boost_angle_radians = deg_to_rad(boost_angle_degrees)

	# Calculate boost vector based on angle and strength
	# Note: In Godot 2D, +Y is down, -Y is up.
	# sin(positive_angle) gives positive Y (downward component for angles 0-180)
	# sin(negative_angle) gives negative Y (upward component for angles 0 to -180)
	# We need to be careful with angle conventions. Assuming 0 degrees is right, 90 is down, -90 is up.
	# Let's adjust the angle interpretation or calculation if needed based on testing.
	# Standard math: angle 0 = right, 90 = up. Godot: angle 0 = right, 90 = down.
	# Let's use standard math angles and negate Y.
	# Rising boost angle 45 deg (up-right) -> standard math angle 45
	# Falling boost angle -60 deg (down-right) -> standard math angle -60

	# Using Vector2.from_angle() might be clearer if angle convention matches Godot's
	# Vector2.from_angle(angle_in_radians) assumes 0 is right, positive is counter-clockwise (up)
	# Let's stick to manual calculation for clarity on Y direction
	var boost_vector = Vector2(
		cos(boost_angle_radians) * boost_strength,
		sin(boost_angle_radians) * boost_strength * -1.0 # Negate Y for Godot's coordinate system
	)

	return boost_vector

# Ensure this class implements the interface (GDScript doesn't enforce this structurally,
# but it's good practice to note). This class implicitly implements IBoostType.
