# scripts/motion/subsystems/ObstacleSystem.gd
# Main entry point for the Obstacle System subsystem.
# Handles obstacle interactions, delegates to specific obstacle types, and applies results.
class_name ObstacleSystem
extends RefCounted
# Implicitly implements IMotionSubsystem (ensure methods match the interface)

# Signals
signal obstacle_hit(entity_id: int, obstacle_name: String, resulting_velocity: Vector2)
signal near_miss(entity_id: int, obstacle_name: String, distance: float)

# Components
var _obstacle_calculator: ObstacleCalculator = null
var _obstacle_type_registry: ObstacleTypeRegistry = null

# Configuration
var _physics_config = null # Will be set via set_physics_config
var _debug_enabled: bool = false

# Initialization logic
func _init() -> void:
	_obstacle_calculator = ObstacleCalculator.new()
	_obstacle_type_registry = ObstacleTypeRegistry.new()
	
	# Register the initial obstacle types
	_register_default_obstacle_types()

# --- Configuration ---

# Sets the physics configuration resource used by obstacle types.
# physics_config: The loaded PhysicsConfig resource.
func set_physics_config(physics_config) -> void:
	_physics_config = physics_config

# Sets debug mode
# enabled: Whether debug mode is enabled
func set_debug_enabled(enabled: bool) -> void:
	_debug_enabled = enabled

# --- Core Logic ---

# Process an obstacle collision
# entity_id: The ID of the entity colliding with the obstacle
# obstacle_node: The obstacle node that was hit
# collision_data: A Dictionary containing collision information
# Returns: An ObstacleOutcome object
func process_obstacle_collision(entity_id: int, obstacle_node: Node2D, collision_data: Dictionary) -> ObstacleOutcome:
	# 1. Check if the node is actually an obstacle
	if not _is_valid_obstacle(obstacle_node):
		push_warning("Node is not a valid obstacle: %s" % obstacle_node.name)
		return ObstacleOutcome.new(collision_data.get("velocity", Vector2.ZERO))
	
	# 2. Create the context object for this obstacle interaction
	var context = ObstacleContext.new_from_collision(collision_data)
	context.entity_id = entity_id
	context.obstacle_node = obstacle_node
	context.physics_config = _physics_config
	
	# 3. Get obstacle types and configs from the obstacle node
	var obstacle_types = _get_obstacle_types(obstacle_node)
	var obstacle_configs = _get_obstacle_configs(obstacle_node)
	
	# 4. Calculate the obstacle outcome
	var outcome = _obstacle_calculator.calculate_obstacle_effect(
		context, obstacle_types, obstacle_configs, _obstacle_type_registry
	)
	
	# 5. Emit signal for successful hit
	if outcome.outcome_type != ObstacleOutcome.OutcomeType.UNAFFECTED:
		emit_signal("obstacle_hit", entity_id, obstacle_node.name, outcome.resulting_velocity)
		
		# 6. Log debug information if enabled
		if _debug_enabled:
			print(outcome.debug_data.get_debug_string())
	
	return outcome

# Check for near misses with obstacles
# entity_id: The ID of the entity to check
# entity_position: The position of the entity
# obstacles: Array of potential obstacle nodes to check
func check_near_misses(entity_id: int, entity_position: Vector2, obstacles: Array) -> void:
	for obstacle in obstacles:
		if not _is_valid_obstacle(obstacle):
			continue
			
		# Get near miss radius from obstacle if available
		var near_miss_radius = 0.0
		if obstacle.has_method("get_near_miss_radius"):
			near_miss_radius = obstacle.get_near_miss_radius()
		elif obstacle.has_method("get_collision_radius"):
			# Fall back to collision radius + buffer
			near_miss_radius = obstacle.get_collision_radius() * 1.5
		else:
			# Skip if we can't determine radius
			continue
			
		# Calculate distance
		var distance = entity_position.distance_to(obstacle.global_position)
		
		# Check if this is a near miss
		if distance <= near_miss_radius and not _is_collision(distance, obstacle):
			emit_signal("near_miss", entity_id, obstacle.name, distance)

# --- Helper Methods ---

# Register default obstacle types
func _register_default_obstacle_types() -> void:
	# Register Weakener type
	var weakener = load("res://scripts/motion/subsystems/obstacle_system/types/Weakener.gd").new()
	_obstacle_type_registry.register_obstacle_type("weakener", weakener)
	
	# Register Deflector type
	var deflector = load("res://scripts/motion/subsystems/obstacle_system/types/Deflector.gd").new()
	_obstacle_type_registry.register_obstacle_type("deflector", deflector)

# Check if a node is a valid obstacle
# node: The node to check
# Returns: True if the node is a valid obstacle, false otherwise
func _is_valid_obstacle(node: Node) -> bool:
	return node != null and node.has_method("get_obstacle_types") and node.has_method("get_obstacle_config")

# Get obstacle types from an obstacle node
# obstacle_node: The obstacle node
# Returns: Array of obstacle type names
func _get_obstacle_types(obstacle_node: Node) -> Array:
	if obstacle_node.has_method("get_obstacle_types"):
		return obstacle_node.get_obstacle_types()
	return []

# Get obstacle configs from an obstacle node
# obstacle_node: The obstacle node
# Returns: Dictionary of obstacle configs
func _get_obstacle_configs(obstacle_node: Node) -> Dictionary:
	if obstacle_node.has_method("get_obstacle_config"):
		return obstacle_node.get_obstacle_config()
	return {}

# Check if a distance represents a collision
# distance: The distance to check
# obstacle: The obstacle node
# Returns: True if the distance represents a collision, false otherwise
func _is_collision(distance: float, obstacle: Node) -> bool:
	var collision_radius = 0.0
	if obstacle.has_method("get_collision_radius"):
		collision_radius = obstacle.get_collision_radius()
	return distance <= collision_radius

# --- IMotionSubsystem Interface Implementation ---

# Returns the unique name of this subsystem.
func get_name() -> String:
	return "ObstacleSystem"

# Called when the subsystem is registered with the MotionSystemCore.
func on_register() -> void:
	# Perform any setup needed upon registration
	pass

# Called when the subsystem is unregistered.
func on_unregister() -> void:
	# Perform any cleanup needed upon unregistration
	pass

# Returns motion modifiers for continuous application.
# This system doesn't apply continuous modifiers.
func get_continuous_modifiers(_delta: float) -> Array:
	return []

# Returns motion modifiers triggered by collisions.
# collision_info: Information about the collision.
# Returns: Array of MotionModifier objects.
func get_collision_modifiers(collision_info: Dictionary) -> Array:
	# Check if the collider is an obstacle
	var collider = collision_info.get("collider", null)
	if not _is_valid_obstacle(collider):
		return []
		
	# Process the obstacle collision
	var entity_id = collision_info.get("entity_id", 0)
	var outcome = process_obstacle_collision(entity_id, collider, collision_info)
	
	# If the outcome didn't modify the motion, return empty array
	if outcome.outcome_type == ObstacleOutcome.OutcomeType.UNAFFECTED:
		return []
		
	# Create a motion modifier from the outcome to set the absolute velocity
	var modifier = MotionModifier.new(
		"ObstacleSystem",           # source
		"set_velocity",             # type (indicates absolute velocity set)
		20,                         # priority (high, adjust if needed)
		outcome.resulting_velocity, # vector (the new velocity)
		1.0,                        # scalar (unused for this type)
		false,                      # is_additive = false (replace current velocity)
		-1                          # duration (instantaneous effect)
	)
	
	return [modifier]

# Declares signals provided by this subsystem.
func get_provided_signals() -> Dictionary:
	return {
		"obstacle_hit": ["int", "String", "Vector2"],
		"near_miss": ["int", "String", "float"]
	}

# Declares signals this subsystem depends on from other subsystems.
func get_signal_dependencies() -> Array:
	return []
