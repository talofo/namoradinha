# scripts/motion/subsystems/obstacle_system/types/Weakener.gd
# Implementation for the Weakener obstacle type.
# Reduces the entity's velocity by a configurable multiplier.
class_name Weakener
extends RefCounted

# Apply the weakening effect to the entity's motion.
# context: An ObstacleContext object containing current state.
# config: Configuration data for this obstacle type.
# Returns: Modified velocity vector after applying the effect.
func apply_effect(context: ObstacleContext, config: Dictionary) -> Vector2:
	var velocity = context.entity_velocity
	var velocity_multiplier = config.get("velocity_multiplier", 0.6)
	var apply_to_x = config.get("apply_to_x", true)
	var apply_to_y = config.get("apply_to_y", true)
	
	# Apply the multiplier to the velocity components
	var new_velocity = Vector2(velocity)
	
	if apply_to_x:
		new_velocity.x *= velocity_multiplier
	
	if apply_to_y:
		new_velocity.y *= velocity_multiplier
	
	return new_velocity

# Check if this obstacle type can affect the entity in the current context.
# context: An ObstacleContext object containing current state.
# config: Configuration data for this obstacle type.
# Returns: True if the obstacle can affect the entity, false otherwise.
func can_affect(_context: ObstacleContext, _config: Dictionary) -> bool:
	# Weakener can affect entities in any state
	return true

# Get debug information about the effect application.
# context: An ObstacleContext object containing current state.
# config: Configuration data for this obstacle type.
# result_velocity: The velocity after applying the effect.
# Returns: A string with debug information.
func get_debug_info(context: ObstacleContext, config: Dictionary, result_velocity: Vector2) -> String:
	var velocity_multiplier = config.get("velocity_multiplier", 0.6)
	var apply_to_x = config.get("apply_to_x", true)
	var apply_to_y = config.get("apply_to_y", true)
	
	var components = []
	if apply_to_x:
		components.append("x")
	if apply_to_y:
		components.append("y")
		
	var components_str = ", ".join(components)
	
	return "Applied Weakener: velocity.%s *= %.2f (before: %s, after: %s)" % [
		components_str,
		velocity_multiplier,
		context.entity_velocity,
		result_velocity
	]

# Get the name of this obstacle type.
# Returns: The name of the obstacle type.
func get_type_name() -> String:
	return "Weakener"
