class_name PhysicsCalculator
extends RefCounted

# Reference to physics config class
# Using LoadedPhysicsConfig to avoid shadowing the global class name
const LoadedPhysicsConfig = preload("res://resources/physics/PhysicsConfig.gd")

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
	var gravity = physics_config.gravity if physics_config else _core.default_gravity
	
	# Physics-based deceleration model: proportional to effective friction and gravity
	var deceleration = effective_friction * gravity * delta
	
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
