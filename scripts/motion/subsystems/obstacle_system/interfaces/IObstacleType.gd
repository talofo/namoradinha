# scripts/motion/subsystems/obstacle_system/interfaces/IObstacleType.gd
# Interface that all obstacle type implementations must follow.
class_name IObstacleType
extends RefCounted

# Apply the obstacle effect to the entity's motion.
# context: An ObstacleContext object containing current state.
# config: Configuration data for this obstacle type.
# Returns: Modified velocity vector after applying the effect.
func apply_effect(context: ObstacleContext, _config: Dictionary) -> Vector2:
	push_error("IObstacleType.apply_effect() must be implemented by subclasses")
	return context.entity_velocity

# Check if this obstacle type can affect the entity in the current context.
# context: An ObstacleContext object containing current state.
# config: Configuration data for this obstacle type.
# Returns: True if the obstacle can affect the entity, false otherwise.
func can_affect(_context: ObstacleContext, _config: Dictionary) -> bool:
	push_error("IObstacleType.can_affect() must be implemented by subclasses")
	return false

# Get debug information about the effect application.
# context: An ObstacleContext object containing current state.
# config: Configuration data for this obstacle type.
# result_velocity: The velocity after applying the effect.
# Returns: A string with debug information.
func get_debug_info(_context: ObstacleContext, _config: Dictionary, _result_velocity: Vector2) -> String:
	return "Obstacle effect applied: %s" % get_type_name()

# Get the name of this obstacle type.
# Returns: The name of the obstacle type.
func get_type_name() -> String:
	push_error("IObstacleType.get_type_name() must be implemented by subclasses")
	return "UnknownObstacleType"
