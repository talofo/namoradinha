class_name ModularLaunchSystem
extends RefCounted

# Signal emitted when an entity is launched
signal entity_launched(entity_id: int, launch_vector: Vector2, position: Vector2)

# Implement the IMotionSubsystem interface
var _motion_system = null

# Component references
var _entity_data = null
var _calculator = null
var _trajectory_predictor = null

func _init() -> void:
	# Initialize components
	_entity_data = load("res://scripts/motion/subsystems/launch_system/data/LaunchEntityData.gd").new()
	_calculator = load("res://scripts/motion/subsystems/launch_system/components/LaunchCalculator.gd").new()
	_trajectory_predictor = load("res://scripts/motion/subsystems/launch_system/components/TrajectoryPredictor.gd").new()

# Returns the subsystem name for debugging
func get_name() -> String:
	return "LaunchSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	# Pass motion system reference to components
	_entity_data.set_motion_system(_motion_system)
	_calculator.set_motion_system(_motion_system)
	_trajectory_predictor.set_motion_system(_motion_system)

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	_motion_system = null

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(_delta: float) -> Array:
	# LaunchSystem doesn't provide continuous modifiers
	return []

# Returns modifiers for collision events
# _collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(_collision_info: Dictionary) -> Array:
	# LaunchSystem doesn't provide collision modifiers
	return []

# Register an entity with the launch system
# entity_id: Unique identifier for the entity
# Returns: True if registration was successful
func register_entity(entity_id: int) -> bool:
	return _entity_data.register_entity(entity_id)

# Unregister an entity from the launch system
# entity_id: Unique identifier for the entity
# Returns: True if unregistration was successful
func unregister_entity(entity_id: int) -> bool:
	return _entity_data.unregister_entity(entity_id)

# Set launch parameters for an entity
# entity_id: Unique identifier for the entity
# angle_degrees: Launch angle in degrees (0-90)
# power: Launch power (0.0-1.0)
# strength: Base magnitude of the launch force
# Returns: True if parameters were set successfully
func set_launch_parameters(entity_id: int, angle_degrees: float, power: float, strength: float = -1.0) -> bool:
	print("[LaunchSystem] set_launch_parameters called - Entity: ", entity_id, ", Angle: ", angle_degrees, ", Power: ", power, ", Strength: ", strength) # DEBUG PRINT
	return _entity_data.set_launch_parameters(entity_id, angle_degrees, power, strength)

# Calculate launch vector for an entity
# entity_id: Unique identifier for the entity
# Returns: The calculated launch vector
func calculate_launch_vector(entity_id: int) -> Vector2:
	var entity_data = _entity_data.get_data(entity_id)
	if entity_data.is_empty():
		return Vector2.ZERO

	var launch_vector = _calculator.calculate_launch_vector(entity_data)

	# Store the launch vector for later reference
	_entity_data.update_launch_vector(entity_id, launch_vector)

	return launch_vector

# Launch an entity with current parameters
# entity_id: Unique identifier for the entity
# position: The current position of the entity being launched
# Returns: The launch vector
func launch_entity(entity_id: int, position: Vector2) -> Vector2:
	print("[LaunchSystem] launch_entity called - Entity: ", entity_id) # DEBUG PRINT
	var current_params = get_launch_parameters(entity_id)
	print("[LaunchSystem] Current params before calc: ", current_params) # DEBUG PRINT
	var launch_vector = calculate_launch_vector(entity_id)
	print("[LaunchSystem] Calculated vector: ", launch_vector) # DEBUG PRINT

	# Emit a signal that the entity was launched
	# This could be used by other systems to react to the launch
	entity_launched.emit(entity_id, launch_vector, position)

	return launch_vector

# Launch an entity with specific parameters
# entity_id: Unique identifier for the entity
# angle_degrees: Launch angle in degrees (0-90)
# power: Launch power (0.0-1.0)
# strength: Base magnitude of the launch force
# position: The current position of the entity being launched
# Returns: The launch vector
func launch_entity_with_parameters(entity_id: int, angle_degrees: float, power: float, strength: float = -1.0, position: Vector2 = Vector2.ZERO) -> Vector2:
	# It's important that the position is passed here if this function is used directly
	set_launch_parameters(entity_id, angle_degrees, power, strength)
	return launch_entity(entity_id, position)

# Get trajectory preview points for UI
# entity_id: Unique identifier for the entity
# num_points: Number of points to generate
# time_step: Time step between points
# Returns: Array of Vector2 points representing the trajectory
func get_preview_trajectory(entity_id: int, num_points: int = 20, time_step: float = 0.1) -> Array:
	var entity_data = _entity_data.get_data(entity_id)
	if entity_data.is_empty():
		return []

	return _trajectory_predictor.calculate_trajectory(entity_data, num_points, time_step)

# Get the last launch vector for an entity
# entity_id: Unique identifier for the entity
# Returns: The last launch vector, or Vector2.ZERO if not found
func get_last_launch_vector(entity_id: int) -> Vector2:
	return _entity_data.get_last_launch_vector(entity_id)

# Get the current launch parameters for an entity
# entity_id: Unique identifier for the entity
# Returns: Dictionary with launch parameters, or empty dictionary if not found
func get_launch_parameters(entity_id: int) -> Dictionary:
	return _entity_data.get_data(entity_id)

# Returns a dictionary of signals this subsystem provides
# The dictionary keys are signal names, values are signal parameter types
# Example: { "entity_launched": ["int", "Vector2", "Vector2"] }
# Returns: Dictionary of provided signals
func get_provided_signals() -> Dictionary:
	return {
		"entity_launched": ["int", "Vector2", "Vector2"]
	}

# Returns an array of signal dependencies this subsystem needs
# Each entry is a dictionary with:
# - "provider": The name of the subsystem providing the signal
# - "signal_name": The name of the signal to connect to
# - "method": The method in this subsystem to connect to the signal
# Example: [{ "provider": "LaunchSystem", "signal_name": "entity_launched", "method": "record_launch" }]
# Returns: Array of signal dependencies
func get_signal_dependencies() -> Array:
	# LaunchSystem doesn't depend on signals from other subsystems
	return []
