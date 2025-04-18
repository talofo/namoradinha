# scripts/motion/subsystems/boost_system/types/ManualAirBoost.gd
# Implementation for the Manual Air Boost type.
# This class implements the IBoostType interface by providing the required methods:
# - can_apply_boost(boost_context)
# - calculate_boost_vector(boost_context)
class_name AirBoostType
extends RefCounted

# No need to preload classes that are globally available via class_name

# Reference to motion system for config access
var _motion_system = null

func set_motion_system(motion_system) -> void:
	_motion_system = motion_system

# Get physics config if available
func _get_physics_config():
	if _motion_system and _motion_system.has_method("get_physics_config"):
		return _motion_system.get_physics_config()
	return null

# Future enhancement point: Add apex detection if needed
# const APEX_VELOCITY_THRESHOLD = 10.0

# Check if the boost can be applied in the current context.
func can_apply_boost(boost_context: BoostContext) -> bool:
	# Manual air boosts can only be applied when airborne
	return boost_context.is_airborne

# Calculate the boost vector to apply based on the context.
func calculate_boost_vector(boost_context: BoostContext) -> Vector2:
	var motion_profile = boost_context.motion_profile
	var boost_strength = 0.0
	var boost_angle_degrees = 0.0

	# Simple approach: Treat based on is_rising flag
	# Future enhancement point: Add special apex handling here if needed
	# Get physics config for fallback values
	var physics_config = _get_physics_config()
	
	if boost_context.is_rising:
		# Get values from motion_profile with fallbacks to physics config
		var default_rising_strength = physics_config.manual_air_boost_rising_strength if physics_config else 300.0
		var default_rising_angle = physics_config.manual_air_boost_rising_angle if physics_config else 45.0
		
		boost_strength = motion_profile.get("manual_air_boost_rising_strength", default_rising_strength)
		boost_angle_degrees = motion_profile.get("manual_air_boost_rising_angle", default_rising_angle)
		
		print("DEBUG: Using rising boost - Strength: %.2f, Angle: %.2f" % [boost_strength, boost_angle_degrees])
	else:
		# Falling (and apex, using the simpler approach)
		var default_falling_strength = physics_config.manual_air_boost_falling_strength if physics_config else 800.0
		var default_falling_angle = physics_config.manual_air_boost_falling_angle if physics_config else -60.0
		
		boost_strength = motion_profile.get("manual_air_boost_falling_strength", default_falling_strength)
		boost_angle_degrees = motion_profile.get("manual_air_boost_falling_angle", default_falling_angle)
		
		print("DEBUG: Using falling boost - Strength: %.2f, Angle: %.2f" % [boost_strength, boost_angle_degrees])

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

	# Apply velocity modifier if available in the motion profile
	var velocity_modifier = motion_profile.get("velocity_modifier", 1.0)
	boost_vector *= velocity_modifier

	return boost_vector

# Ensure this class implements the interface (GDScript doesn't enforce this structurally,
# but it's good practice to note). This class implicitly implements IBoostType.
