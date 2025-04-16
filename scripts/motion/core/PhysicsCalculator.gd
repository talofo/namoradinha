class_name PhysicsCalculator
extends RefCounted

# PhysicsConfig is available globally via class_name

# Reference to the motion system core
var _core = null

func _init(core) -> void:
	_core = core

# Get appropriate gravity based on entity type and mass
# entity_type: Type of entity (e.g., "player", "enemy")
# mass: Mass of the entity
# Returns: The gravity value to use
func get_gravity_for_entity(entity_type: String, mass: float) -> float:
	var physics_config = _core.get_physics_config()
	
	if physics_config and physics_config.has_method("get_gravity_for_entity"):
		return physics_config.get_gravity_for_entity(entity_type, mass)
	
	# Fallback to default gravity
	return _core.default_gravity

# Apply gravity to velocity
# velocity: Current velocity
# delta: Time since last frame
# entity_type: Type of entity (e.g., "player", "enemy")
# mass: Mass of the entity
# Returns: The updated velocity
func apply_gravity(velocity: Vector2, delta: float, entity_type: String = "default", mass: float = 1.0) -> Vector2:
	var gravity = get_gravity_for_entity(entity_type, mass)
	velocity.y += gravity * delta
	return velocity

# Calculate deceleration for sliding
# speed: Current speed
# delta: Time since last frame
# effective_friction: Friction coefficient
# Returns: The deceleration value
func calculate_deceleration(speed: float, delta: float, effective_friction: float) -> float:
	var physics_config = _core.get_physics_config()
	
	if not physics_config:
		# Fallback to simple physics-based model if no config
		var gravity = _core.default_gravity
		var deceleration = effective_friction * gravity * delta
		deceleration = min(deceleration, speed)
		return deceleration
	
	# Get deceleration parameters from physics config
	var base_decel = physics_config.deceleration_base
	var speed_factor = physics_config.deceleration_speed_factor
	var max_factor = physics_config.max_deceleration_factor
	var frame_adjustment = physics_config.frame_rate_adjustment
	
	# Calculate deceleration using the parameters from config
	# Base deceleration + speed-based component
	var decel_factor = base_decel + (speed * speed_factor)
	
	# Cap at maximum deceleration factor
	decel_factor = min(decel_factor, max_factor)
	
	# Apply to current speed, adjusted for framerate
	var target_fps = frame_adjustment
	var current_fps = 1.0 / delta
	var fps_ratio = target_fps / current_fps
	
	var deceleration = speed * decel_factor * fps_ratio
	
	# Debug output
	print("DEBUG: Deceleration calculation - Speed: %.2f, Factor: %.4f, Result: %.2f" % [speed, decel_factor, deceleration])
	
	# Ensure deceleration doesn't reverse velocity direction in one frame
	deceleration = min(deceleration, speed)
	
	return deceleration

# Check if an entity should stop sliding
# speed: Current horizontal speed (absolute value of x component)
# Returns: True if the entity should stop sliding
func should_stop_sliding(speed: float) -> bool:
	var physics_config = _core.get_physics_config()
	var stop_threshold = physics_config.default_stop_threshold if physics_config else _core.default_stop_threshold
	
	# Only consider horizontal speed for stopping
	return speed < stop_threshold

# Get base friction for a material
# material_type: Type of material
# Returns: The base friction value
func get_base_friction(material_type: String) -> float:
	var physics_config = _core.get_physics_config()
	var base_friction = physics_config.default_ground_friction if physics_config else _core.default_ground_friction
	
	var collision_material_system = _core.get_subsystem("CollisionMaterialSystem")
	if collision_material_system:
		var material_properties = collision_material_system.get_material_properties(material_type)
		base_friction = material_properties.get("friction", base_friction)
	
	return base_friction

# Check if a collision is with the floor
# collision_info: Information about the collision
# Returns: True if the collision is with the floor
func is_floor_collision(collision_info: Dictionary) -> bool:
	var normal = collision_info.get("normal", Vector2.ZERO)
	return normal.y < -0.7  # Consider surfaces with normals pointing mostly up as floors

# Round velocity to reduce visual jittering
# velocity: Current velocity
# Returns: The rounded velocity
func round_velocity(velocity: Vector2) -> Vector2:
	velocity.x = round(velocity.x * 10) / 10.0
	velocity.y = round(velocity.y * 10) / 10.0
	return velocity
