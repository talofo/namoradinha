class_name ModularBounceSystem
extends RefCounted

# Implement the IMotionSubsystem interface
var _motion_system = null

# Component references
var _entity_data = null
var _calculator = null

func _init() -> void:
	# Initialize components
	_entity_data = load("res://scripts/motion/subsystems/bounce_system/data/BounceEntityData.gd").new()
	_calculator = load("res://scripts/motion/subsystems/bounce_system/components/BounceCalculator.gd").new()

# Returns the subsystem name for debugging
func get_name() -> String:
	return "BounceSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	# Pass motion system reference to components
	_entity_data.set_motion_system(_motion_system)
	_calculator.set_motion_system(_motion_system)

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	_motion_system = null

# Returns modifiers for frame-based updates
# delta: Time since last frame
# Returns: Array of MotionModifier objects
func get_continuous_modifiers(_delta: float) -> Array:
	# Bounce system doesn't provide continuous modifiers
	return []

# Returns modifiers for collision events
# collision_info: Information about the collision
# Returns: Array of MotionModifier objects
func get_collision_modifiers(collision_info: Dictionary) -> Array:
	var modifiers = []
	var entity_id = collision_info.get("entity_id", 0)
	
	# Only process if we have data for this entity and it's a floor collision
	if not _entity_data.has_entity(entity_id) or not _calculator.is_floor_collision(collision_info):
		return modifiers
	
	var bounce_data = _entity_data.get_data(entity_id)
	
	# Update floor position
	_entity_data.update_floor_position(entity_id, collision_info.get("position", Vector2.ZERO))
	
	# Reset max height tracking for this bounce cycle if this is a new bounce
	# This ensures we start tracking from the floor position
	if bounce_data.bounce_count > 0:
		ErrorHandler.debug("BounceSystem", "Resetting max height tracking for bounce " + str(bounce_data.bounce_count + 1))
		# Force reset max height to current position
		_entity_data.force_reset_max_height(entity_id, collision_info.get("position", Vector2.ZERO))
	
	# Calculate bounce response
	var bounce_vector = _calculator.calculate_bounce_vector(bounce_data, collision_info)
	
	# Get physics config for bounce calculations
	var physics_config = _motion_system.get_physics_config()
	
	# Let the bounce calculator determine the target height
	# The bounce vector calculation already includes the target height calculation
	# We just need to extract the target height from the bounce data after the calculation
	
	ErrorHandler.info("BounceSystem", "Using bounce calculator to determine target height - bounce_count=" + str(bounce_data.bounce_count) + 
		", current_target_height=" + str(bounce_data.current_target_height))
	
	# The bounce calculator will update the target height internally during the calculation
	# We don't need to manually calculate it here anymore
	
	# Update the target height in entity data based on the bounce calculator's result
	# We can extract this from the bounce vector's y component and the gravity
	var target_height = 0.0
	if bounce_vector.y < 0:  # Negative y velocity means upward motion
		var gravity = physics_config.get_gravity_for_entity(collision_info.get("entity_type", "default"), 
			collision_info.get("mass", 1.0))
		# Using physics formula: h = v²/2g (where v is the initial upward velocity)
		target_height = (bounce_vector.y * bounce_vector.y) / (2 * gravity)
		target_height = abs(target_height)  # Ensure positive value
	else:
		# If not bouncing upward, set target height to 0
		target_height = 0.0
	
	ErrorHandler.info("BounceSystem", "Calculated target height: " + str(target_height))
	
	# Update the target height in entity data
	_entity_data.update_target_height(entity_id, target_height)
	
	# Create a bounce modifier
	var bounce_modifier = load("res://scripts/motion/MotionModifier.gd").new(
		"BounceSystem",    # source
		"velocity",        # type
		20,                # priority (high)
		bounce_vector,     # vector (calculated bounce response)
		1.0,               # scalar
		false,             # is_additive (replace velocity)
		-1                 # duration (permanent)
	)
	
	modifiers.append(bounce_modifier)
	
	# Increment bounce count
	_entity_data.increment_bounce_count(entity_id)
	
	# Reset max height tracking for the next bounce
	# Use the current position instead of floor position to allow proper height tracking during the next bounce
	# We use update_max_height here instead of force_reset_max_height because we want to track the highest point
	# during the bounce arc, not just reset it
	_entity_data.update_max_height(entity_id, collision_info.get("position", Vector2.ZERO))
	
	return modifiers

# Register an entity with the bounce system
# entity_id: Unique identifier for the entity
# position: Initial position of the entity
# Returns: True if registration was successful
func register_entity(entity_id: int, position: Vector2) -> bool:
	return _entity_data.register_entity(entity_id, position)

# Unregister an entity from the bounce system
# entity_id: Unique identifier for the entity
# Returns: True if unregistration was successful
func unregister_entity(entity_id: int) -> bool:
	return _entity_data.unregister_entity(entity_id)

# Record a launch for an entity
# entity_id: Unique identifier for the entity
# velocity: Launch velocity
# position: Launch position
func record_launch(entity_id: int, velocity: Vector2, position: Vector2) -> void:
	_entity_data.record_launch(entity_id, velocity, position)

# Update the maximum height reached by an entity
# entity_id: Unique identifier for the entity
# position: Current position of the entity
func update_max_height(entity_id: int, position: Vector2) -> void:
	_entity_data.update_max_height(entity_id, position)

# Get the current bounce count for an entity
# entity_id: Unique identifier for the entity
# Returns: The current bounce count, or -1 if the entity is not registered
func get_bounce_count(entity_id: int) -> int:
	return _entity_data.get_bounce_count(entity_id)

# Check if an entity should stop bouncing
# entity_id: Unique identifier for the entity
# Returns: True if the entity should stop bouncing
func should_stop_bouncing(entity_id: int) -> bool:
	var entity_data = _entity_data.get_data(entity_id)
	if entity_data.is_empty():
		return true
	
	return _calculator.should_stop_bouncing(entity_data)

# Returns a dictionary of signals this subsystem provides
# The dictionary keys are signal names, values are signal parameter types
# Returns: Dictionary of provided signals
func get_provided_signals() -> Dictionary:
	# BounceSystem doesn't provide any signals
	return {}

# Returns an array of signal dependencies this subsystem needs
# Each entry is a dictionary with:
# - "provider": The name of the subsystem providing the signal
# - "signal_name": The name of the signal to connect to
# - "method": The method in this subsystem to connect to the signal
# Returns: Array of signal dependencies
func get_signal_dependencies() -> Array:
	return [
		{
			"provider": "LaunchSystem",
			"signal_name": "entity_launched",
			"method": "record_launch"
		}
	]
