class_name BounceSystem
extends RefCounted

# Reference to physics config class
# Using LoadedPhysicsConfig to avoid shadowing the global class name
const LoadedPhysicsConfig = preload("res://resources/physics/PhysicsConfig.gd")

# Implement the IMotionSubsystem interface
# No need for _motion_system variable as it's not used

# Physics configuration resource
var physics_config: LoadedPhysicsConfig

# Entity bounce data storage
# Structure:
# {
#   entity_id: {
#     bounce_count: int,
#     launch_position_y: float,
#     floor_position_y: float,
#     max_height_y: float,
#     current_target_height: float,
#     launch_velocity: Vector2
#   }
# }
var _entity_bounce_data = {}

# Reference to the motion system (set during registration)
var _motion_system = null

# Returns the subsystem name for debugging
func get_name() -> String:
	return "BounceSystem"

# Called when the subsystem is registered with the MotionSystem
func on_register() -> void:
	# _motion_system reference is set by MotionSystem just before calling this.
	# Config is fetched dynamically later when needed.
	pass # No action needed here now

# Called when the subsystem is unregistered from the MotionSystem
func on_unregister() -> void:
	pass

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
	if not _entity_bounce_data.has(entity_id) or not is_floor_collision(collision_info):
		return modifiers
	
	var bounce_data = _entity_bounce_data[entity_id]
	
	# Ensure motion system and config are available
	if not _motion_system or not _motion_system.has_method("get_physics_config"):
		push_error("[BounceSystem] MotionSystem or get_physics_config method not available.")
		return modifiers
	var current_physics_config = _motion_system.get_physics_config()
	if not current_physics_config:
		push_error("[BounceSystem] Physics config not available from MotionSystem.")
		return modifiers
		
	# Update floor position
	bounce_data.floor_position_y = collision_info.get("position", Vector2.ZERO).y
	
	# Calculate bounce response
	var bounce_vector = calculate_bounce_vector(entity_id, collision_info)
	
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
	bounce_data.bounce_count += 1
	
	# Reset max height tracking for the next bounce
	bounce_data.max_height_y = bounce_data.floor_position_y
	
	return modifiers

# Register an entity with the bounce system
# entity_id: Unique identifier for the entity
# position: Initial position of the entity
# Returns: True if registration was successful
func register_entity(entity_id: int, position: Vector2) -> bool:
	if _entity_bounce_data.has(entity_id):
		return false
	
	_entity_bounce_data[entity_id] = {
		"bounce_count": 0,
		"launch_position_y": position.y,
		"floor_position_y": position.y,
		"max_height_y": position.y,
		"current_target_height": 0.0,
		"launch_velocity": Vector2.ZERO
	}
	return true

# Unregister an entity from the bounce system
# entity_id: Unique identifier for the entity
# Returns: True if unregistration was successful
func unregister_entity(entity_id: int) -> bool:
	if not _entity_bounce_data.has(entity_id):
		return false
	
	_entity_bounce_data.erase(entity_id)
	return true

# Record a launch for an entity
# entity_id: Unique identifier for the entity
# velocity: Launch velocity
# position: Launch position
func record_launch(entity_id: int, velocity: Vector2, position: Vector2) -> void:
	print("BounceSystem: Recording launch for entity ", entity_id, " with velocity ", velocity, " at position ", position)
	
	if not _entity_bounce_data.has(entity_id):
		register_entity(entity_id, position)
		# print("BounceSystem: Entity registered") # Keep original print if desired
	
	var bounce_data = _entity_bounce_data[entity_id]
	bounce_data.bounce_count = 0
	bounce_data.launch_velocity = velocity
	bounce_data.launch_position_y = position.y
	bounce_data.floor_position_y = position.y
	bounce_data.max_height_y = position.y
	bounce_data.current_target_height = 0.0
	
	print("BounceSystem: Launch data recorded - launch_position_y=", position.y)

# Update the maximum height reached by an entity
# entity_id: Unique identifier for the entity
# position: Current position of the entity
func update_max_height(entity_id: int, position: Vector2) -> void:
	if not _entity_bounce_data.has(entity_id):
		return
	
	var bounce_data = _entity_bounce_data[entity_id]
	if position.y < bounce_data.max_height_y:
		bounce_data.max_height_y = position.y

# Get the current bounce count for an entity
# entity_id: Unique identifier for the entity
# Returns: The current bounce count, or -1 if the entity is not registered
func get_bounce_count(entity_id: int) -> int:
	if not _entity_bounce_data.has(entity_id):
		return -1
	
	return _entity_bounce_data[entity_id].bounce_count

# Check if a collision is with the floor
# collision_info: Information about the collision
# Returns: True if the collision is with the floor
func is_floor_collision(collision_info: Dictionary) -> bool:
	var normal = collision_info.get("normal", Vector2.ZERO)
	return normal.y < -0.7  # Consider surfaces with normals pointing mostly up as floors

	# Calculate the bounce vector for an entity
# entity_id: Unique identifier for the entity
# collision_info: Information about the collision (NOW USED for current velocity)
# Returns: The bounce vector
func calculate_bounce_vector(entity_id: int, collision_info: Dictionary) -> Vector2:
	var bounce_data = _entity_bounce_data[entity_id]
	
	# Get entity properties
	var entity_type = collision_info.get("entity_type", "default")
	var entity_mass = collision_info.get("mass", physics_config.default_mass if physics_config else 1.0)
	
	# Ensure motion system and config are available
	if not _motion_system or not _motion_system.has_method("get_physics_config"):
		push_error("[BounceSystem] MotionSystem or get_physics_config method not available.")
		return Vector2.ZERO
	var current_physics_config = _motion_system.get_physics_config()
	if not current_physics_config:
		push_error("[BounceSystem] Physics config not available from MotionSystem.")
		return Vector2.ZERO
		
	# Get gravity from config
	var gravity = current_physics_config.get_gravity_for_entity(entity_type, entity_mass)
		
	# Calculate the max height achieved relative to floor
	# Important: This calculation should always result in a positive value
	var max_height_reached = bounce_data.floor_position_y - bounce_data.max_height_y
	
	# Debug the height calculation (Restored original print)
	print("BounceSystem: floor_position_y=", bounce_data.floor_position_y, 
		  " max_height_y=", bounce_data.max_height_y, 
		  " calculated max_height_reached=", max_height_reached)
	
	# Ensure we have a sensible positive value even if position tracking had issues
	if max_height_reached <= 10:
		# If tracking gave us invalid height, use the magnitude of the original launch Y velocity
		# to estimate how high the player would have gone using basic physics formula: h = v²/2g
		var launch_velocity_y_magnitude = abs(bounce_data.launch_velocity.y)
		max_height_reached = (launch_velocity_y_magnitude * launch_velocity_y_magnitude) / (2 * gravity)
		print("BounceSystem: Using velocity-based height estimate instead: ", max_height_reached) # Restored original print
	
	# Calculate bounce based on height reached using config values
	var current_first_bounce_ratio = current_physics_config.first_bounce_ratio
	var current_subsequent_bounce_ratio = current_physics_config.subsequent_bounce_ratio
	
	# Calculate target height for this bounce
	var target_height = 0.0
	if bounce_data.bounce_count == 0:
		# First bounce - relative to max launch height
		target_height = max_height_reached * current_first_bounce_ratio
		bounce_data.current_target_height = target_height
		# First bounce calculation
	else:
		# Subsequent bounces - relative to previous bounce target
		target_height = bounce_data.current_target_height * current_subsequent_bounce_ratio
		bounce_data.current_target_height = target_height
		# Subsequent bounce calculation
	
	# Calculate required velocity to reach that height
	# Using physics formula: v = sqrt(2 * g * h)
	var bounce_velocity_y = 0.0
	
	# Use ORIGINAL launch velocity for horizontal momentum, with consistent reduction based on bounce count
	# This prevents the horizontal velocity from increasing with each bounce
	var current_horizontal_preservation = current_physics_config.horizontal_preservation
	current_horizontal_preservation = pow(current_horizontal_preservation, bounce_data.bounce_count)  # reduction per bounce
	var bounce_velocity_x = bounce_data.launch_velocity.x * current_horizontal_preservation

	print("BounceSystem: target_height=", target_height, " bounce_count=", bounce_data.bounce_count) # Restored original print

	# Get minimum bounce threshold from physics config
	var current_min_bounce_threshold = current_physics_config.min_bounce_threshold
	
	if target_height >= current_min_bounce_threshold:
		bounce_velocity_y = -sqrt(2 * gravity * target_height)
		print("BounceSystem: Continuing to bounce with velocity_y=", bounce_velocity_y) # Restored original print
	else:
		# Below minimum bounce threshold - stop bouncing and start sliding
		bounce_velocity_y = 0.0  # Ensure y velocity is exactly zero for sliding
		
		# When transitioning to sliding, use the CURRENT horizontal velocity
		# This ensures a smooth transition from bouncing to sliding
		bounce_velocity_x = bounce_velocity_x  # Keep the current reduced horizontal velocity
		print("BounceSystem: Stopping bounce, transitioning to slide with velocity_x=", bounce_velocity_x) # Restored original print

		# Get minimum slide speed from physics config
		var current_min_slide_speed = current_physics_config.min_slide_speed
		
		# Entity mass affects minimum slide speed (heavier entities need more speed)
		var mass_adjusted_min_speed = current_min_slide_speed * (0.8 + entity_mass * 0.2)
		
		if abs(bounce_velocity_x) < mass_adjusted_min_speed and bounce_velocity_x != 0.0:
			# Preserve direction but ensure minimum sliding speed
			bounce_velocity_x = sign(bounce_velocity_x) * mass_adjusted_min_speed
			print("BounceSystem: Boosting slide velocity to ", bounce_velocity_x) # Restored original print
		
		# Apply an initial velocity adjustment based on mass
		# Lighter entities get more initial speed boost
		var boost_factor = 1.5 * (1.1 - entity_mass * 0.1) # Range 1.0-1.1 based on mass
		bounce_velocity_x *= boost_factor
		print("BounceSystem: Applied mass-adjusted boost factor ", boost_factor) # Restored original print
	
	var bounce_vector = Vector2(bounce_velocity_x, bounce_velocity_y)
	print("BounceSystem: Final bounce vector=", bounce_vector) # Restored original print
	
	return bounce_vector

# Check if an entity should stop bouncing
# entity_id: Unique identifier for the entity
# Returns: True if the entity should stop bouncing
func should_stop_bouncing(entity_id: int) -> bool:
	if not _entity_bounce_data.has(entity_id):
		return true
	
	var bounce_data = _entity_bounce_data[entity_id]
	var target_height = bounce_data.current_target_height
	
	# Ensure motion system and config are available
	if not _motion_system or not _motion_system.has_method("get_physics_config"):
		push_error("[BounceSystem] MotionSystem or get_physics_config method not available.")
		return true # Assume stop if config is missing
	var current_physics_config = _motion_system.get_physics_config()
	if not current_physics_config:
		push_error("[BounceSystem] Physics config not available from MotionSystem.")
		return true # Assume stop if config is missing
		
	# Get minimum bounce threshold from physics config
	var current_min_bounce_threshold = current_physics_config.min_bounce_threshold
	
	return target_height < current_min_bounce_threshold
