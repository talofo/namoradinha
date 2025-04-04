class_name LaunchSystem
extends RefCounted

# Reference to physics config class
# Using LoadedPhysicsConfig to avoid shadowing the global class name
const LoadedPhysicsConfig = preload("res://resources/physics/PhysicsConfig.gd")

# Implement the IMotionSubsystem interface
var _motion_system = null

# Physics configuration resource
var physics_config: LoadedPhysicsConfig

# Launch configuration
var default_launch_strength: float = 1500.0
var default_launch_angle_degrees: float = 45.0

# Entity launch data storage
# Structure:
# {
#   entity_id: {
#     launch_power: float,
#     launch_angle_degrees: float,
#     launch_strength: float,
#     last_launch_vector: Vector2,
#     last_launch_time: float
#   }
# }
var _entity_launch_data = {}

func _init() -> void:
	print("[LaunchSystem] Initialized")
	
	# Load physics configuration
	var config_path = "res://resources/physics/default_physics.tres"
	if ResourceLoader.exists(config_path):
		physics_config = load(config_path) as LoadedPhysicsConfig
		if physics_config:
			# Update default parameters from config if they exist
			if physics_config.get("default_launch_strength"):
				default_launch_strength = physics_config.default_launch_strength
			if physics_config.get("default_launch_angle_degrees"):
				default_launch_angle_degrees = physics_config.default_launch_angle_degrees
		else:
			push_warning("[LaunchSystem] Failed to load physics config as PhysicsConfig resource")
	else:
		push_warning("[LaunchSystem] Physics config not found at " + config_path)

# Returns the subsystem name for debugging
func get_name() -> String:
	return "LaunchSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	print("[LaunchSystem] Registered with MotionSystem")
	# The motion system will be set externally when registered
	# We don't use get_parent() because RefCounted doesn't have that method

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	print("[LaunchSystem] Unregistered from MotionSystem")
	_motion_system = null

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(_delta: float) -> Array:
	# LaunchSystem doesn't provide continuous modifiers
	return []

# Returns modifiers for collision events
# collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	# LaunchSystem doesn't provide collision modifiers
	return []

# Register an entity with the launch system
# entity_id: Unique identifier for the entity
# Returns: True if registration was successful
func register_entity(entity_id: int) -> bool:
	if _entity_launch_data.has(entity_id):
		return false
	
	_entity_launch_data[entity_id] = {
		"launch_power": 1.0,
		"launch_angle_degrees": default_launch_angle_degrees,
		"launch_strength": default_launch_strength,
		"last_launch_vector": Vector2.ZERO,
		"last_launch_time": 0.0
	}
	return true

# Unregister an entity from the launch system
# entity_id: Unique identifier for the entity
# Returns: True if unregistration was successful
func unregister_entity(entity_id: int) -> bool:
	if not _entity_launch_data.has(entity_id):
		return false
	
	_entity_launch_data.erase(entity_id)
	return true

# Set launch parameters for an entity
# entity_id: Unique identifier for the entity
# angle_degrees: Launch angle in degrees (0-90)
# power: Launch power (0.0-1.0)
# strength: Base magnitude of the launch force
# Returns: True if parameters were set successfully
func set_launch_parameters(entity_id: int, angle_degrees: float, power: float, strength: float = -1.0) -> bool:
	if not _entity_launch_data.has(entity_id):
		if not register_entity(entity_id):
			return false
	
	var launch_data = _entity_launch_data[entity_id]
	launch_data.launch_angle_degrees = clamp(angle_degrees, 0, 90)
	launch_data.launch_power = clamp(power, 0.1, 1.0)
	
	if strength > 0:
		launch_data.launch_strength = strength
	
	return true

# Calculate launch vector for an entity
# entity_id: Unique identifier for the entity
# Returns: The calculated launch vector
func calculate_launch_vector(entity_id: int) -> Vector2:
	if not _entity_launch_data.has(entity_id):
		push_warning("[LaunchSystem] Entity not registered: " + str(entity_id))
		return Vector2.ZERO
	
	var launch_data = _entity_launch_data[entity_id]
	
	# Convert angle to radians
	var angle_radians = deg_to_rad(launch_data.launch_angle_degrees)
	
	# Calculate direction vector based on angle
	# In Godot, 0 degrees is right, 90 is up, 180 is left, 270 is down
	var direction = Vector2(
		cos(angle_radians),  # X component
		-sin(angle_radians)  # Y component (negative since Y increases downward)
	)
	
	# Calculate final launch vector
	var launch_magnitude = launch_data.launch_strength * launch_data.launch_power
	var launch_vector = direction * launch_magnitude
	
	# Store the launch vector for later reference
	launch_data.last_launch_vector = launch_vector
	launch_data.last_launch_time = Time.get_ticks_msec() / 1000.0
	
	return launch_vector

# Launch an entity with current parameters
# entity_id: Unique identifier for the entity
# Returns: The launch vector
func launch_entity(entity_id: int) -> Vector2:
	var launch_vector = calculate_launch_vector(entity_id)
	
	print("[LaunchSystem] Launching entity ", entity_id, " with vector ", launch_vector)
	
	# Emit a signal that the entity was launched
	# This could be used by other systems to react to the launch
	if _motion_system and _motion_system.has_signal("entity_launched"):
		_motion_system.emit_signal("entity_launched", entity_id, launch_vector)
	
	return launch_vector

# Launch an entity with specific parameters
# entity_id: Unique identifier for the entity
# angle_degrees: Launch angle in degrees (0-90)
# power: Launch power (0.0-1.0)
# strength: Base magnitude of the launch force
# Returns: The launch vector
func launch_entity_with_parameters(entity_id: int, angle_degrees: float, power: float, strength: float = -1.0) -> Vector2:
	set_launch_parameters(entity_id, angle_degrees, power, strength)
	return launch_entity(entity_id)

# Get trajectory preview points for UI
# entity_id: Unique identifier for the entity
# num_points: Number of points to generate
# time_step: Time step between points
# Returns: Array of Vector2 points representing the trajectory
func get_preview_trajectory(entity_id: int, num_points: int = 20, time_step: float = 0.1) -> Array:
	if not _entity_launch_data.has(entity_id):
		push_warning("[LaunchSystem] Entity not registered for trajectory preview: " + str(entity_id))
		return []
	
	var launch_data = _entity_launch_data[entity_id]
	var points = []
	
	# Calculate initial velocity
	var angle_radians = deg_to_rad(launch_data.launch_angle_degrees)
	var initial_velocity = Vector2(
		cos(angle_radians) * launch_data.launch_strength * launch_data.launch_power,
		-sin(angle_radians) * launch_data.launch_strength * launch_data.launch_power
	)
	
	# Get gravity from physics config or use default
	var gravity = 1200.0  # Default fallback
	if physics_config and physics_config.has_method("get_gravity_for_entity"):
		gravity = physics_config.get_gravity_for_entity("default", 1.0)
	
	# Simple physics simulation to get trajectory points
	var pos = Vector2.ZERO
	var vel = initial_velocity
	
	for i in range(num_points):
		points.append(pos)
		vel.y += gravity * time_step
		pos += vel * time_step
		
		# Optional: Stop if we hit the ground (y > 0)
		# This assumes the ground is at y=0, adjust as needed
		if pos.y > 0:
			points.append(Vector2(pos.x, 0))
			break
	
	return points

# Get the last launch vector for an entity
# entity_id: Unique identifier for the entity
# Returns: The last launch vector, or Vector2.ZERO if not found
func get_last_launch_vector(entity_id: int) -> Vector2:
	if not _entity_launch_data.has(entity_id):
		return Vector2.ZERO
	
	return _entity_launch_data[entity_id].last_launch_vector

# Get the current launch parameters for an entity
# entity_id: Unique identifier for the entity
# Returns: Dictionary with launch parameters, or empty dictionary if not found
func get_launch_parameters(entity_id: int) -> Dictionary:
	if not _entity_launch_data.has(entity_id):
		return {}
	
	return _entity_launch_data[entity_id].duplicate()
