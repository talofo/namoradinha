# scripts/motion/subsystems/obstacle_system/components/ObstacleCalculator.gd
# Component responsible for calculating the obstacle outcome based on context and type.
class_name ObstacleCalculator
extends RefCounted

# Calculate the outcome of an obstacle interaction.
# context: The ObstacleContext containing current state.
# obstacle_types: Array of obstacle type names to apply.
# obstacle_configs: Dictionary of configurations for each obstacle type.
# Returns: An ObstacleOutcome object.
func calculate_obstacle_effect(context: ObstacleContext, obstacle_types: Array, 
							  obstacle_configs: Dictionary, type_registry: ObstacleTypeRegistry) -> ObstacleOutcome:
	# Create an outcome object to store results
	var outcome = ObstacleOutcome.new(context.entity_velocity)
	
	# Set debug data
	if context.obstacle_node and context.obstacle_node.has_method("get_name"):
		outcome.debug_data.obstacle_name = context.obstacle_node.get_name()
	
	# Apply each obstacle type sequentially
	for type_name in obstacle_types:
		# Skip if the type isn't registered
		if not type_registry.has_obstacle_type(type_name):
			push_warning("Obstacle type not found: %s" % type_name)
			continue
			
		# Get the obstacle type instance
		var obstacle_type = type_registry.get_obstacle_type(type_name)
		
		# Get the configuration for this type
		var config = obstacle_configs.get(type_name, {})
		
		# Check if this type can affect the entity
		if not obstacle_type.can_affect(context, config):
			continue
			
		# Apply the effect
		var new_velocity = obstacle_type.apply_effect(context, config)
		
		# Update the outcome
		outcome.set_modified(new_velocity)
		outcome.add_effect(type_name)
		
		# Add debug info
		var debug_info = obstacle_type.get_debug_info(context, config, new_velocity)
		outcome.debug_data.log_effect(type_name, debug_info)
		
		# Check for STOPPED outcome
		if new_velocity.is_zero_approx():
			outcome.set_stopped()
			break
	
	# Validate direction (never send player backward unless explicitly allowed)
	if not _validate_direction(context.entity_velocity, outcome.resulting_velocity, obstacle_configs):
		# If direction validation fails, adjust the velocity to maintain forward motion
		outcome.resulting_velocity.x = max(outcome.resulting_velocity.x, 0)
		outcome.debug_data.log_effect("direction_validator", "Prevented backward motion")
	
	return outcome

# Validate that the resulting direction doesn't send the player backward
# original_velocity: The original velocity before obstacle effect
# new_velocity: The calculated velocity after obstacle effect
# configs: The obstacle configurations
# Returns: True if the direction is valid, false otherwise
func _validate_direction(original_velocity: Vector2, new_velocity: Vector2, configs: Dictionary) -> bool:
	# Check if any config explicitly allows backward motion
	var allow_backward = configs.get("allow_backward", false)
	
	# If backward motion is allowed, return true
	if allow_backward:
		return true
		
	# If the player was moving forward (positive X) and would now move backward (negative X),
	# return false to indicate invalid direction
	if original_velocity.x > 0 and new_velocity.x < 0:
		return false
		
	# Otherwise, the direction is valid
	return true
