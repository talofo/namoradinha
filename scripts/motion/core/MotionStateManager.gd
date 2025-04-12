class_name MotionStateManager
extends RefCounted

# Reference to the motion system core
var _core = null

func _init(core) -> void:
	_core = core

# Resolve frame motion (called every physics frame)
# context: Dictionary containing motion context (position, velocity, delta, etc.)
# Returns: Dictionary containing motion result (velocity, has_launched, is_sliding, etc.)
func resolve_frame_motion(context: Dictionary) -> Dictionary:
	var result = {}
	
	# Apply gravity if entity is launched and not in post-bounce period
	if context.has("has_launched") and context.get("has_launched"):
		var skip_gravity = context.get("skip_gravity", false)
		
		if not skip_gravity:
			var velocity = context.get("velocity", Vector2.ZERO)
			var delta = context.get("delta", 0.01) # Fallback to 0.01 if no delta

			# Get appropriate gravity based on entity type and mass
			var entity_type = context.get("entity_type", "default")
			var mass = context.get("mass", _core.physics_config.default_mass if _core.physics_config else 1.0)
			
			# Apply gravity
			velocity = _core.physics_calculator.apply_gravity(velocity, delta, entity_type, mass)
			result["velocity"] = velocity
		else:
			# Skip gravity, just pass through the current velocity
			result["velocity"] = context.get("velocity", Vector2.ZERO)

	# Get continuous motion modifiers
	var motion_delta: Vector2 = Vector2.ZERO # Declare motion_delta with default value
	var player_node = context.get("player_node", null) # Extract player_node from context
	if not is_instance_valid(player_node):
		push_error("MotionStateManager: Invalid player_node in context for resolve_continuous_motion.")
		# If player node is invalid, we can't resolve profile, skip continuous motion step
		motion_delta = Vector2.ZERO 
	else:
		motion_delta = _core.resolve_continuous_motion(
			player_node, # Pass player_node first
			context.get("delta", 0.0),
			context.get("is_sliding", false)
		)
	
	# Apply continuous motion modifiers to velocity
	if result.has("velocity"):
		result["velocity"] += motion_delta
	else:
		result["velocity"] = context.get("velocity", Vector2.ZERO) + motion_delta
	
	# Round velocity values to reduce visual jittering from small incremental changes
	result["velocity"] = _core.physics_calculator.round_velocity(result["velocity"])

	return result

# Handle state transition from bouncing to sliding
# velocity: Current velocity
# Returns: Dictionary with updated state information
func transition_to_sliding(velocity: Vector2) -> Dictionary:
	var result = {}
	
	# Preserve x-velocity with a small reduction to make the transition smoother
	var preserved_x_velocity = velocity.x * 0.98  # No velocity clamping to allow for unlimited jump heights
	result["velocity"] = Vector2(preserved_x_velocity, 0.0)
	result["has_launched"] = false
	result["is_sliding"] = true

	return result

# Handle state transition from sliding to stopped
# Returns: Dictionary with updated state information
func transition_to_stopped() -> Dictionary:
	var result = {}
	
	result["velocity"] = Vector2.ZERO
	result["is_sliding"] = false
	result["just_stopped_sliding"] = true # Flag that we just stopped

	return result

# Update sliding state
# velocity: Current velocity
# delta: Time since last frame
# material_type: Type of material being slid on
# Returns: Dictionary with updated state information
func update_sliding_state(velocity: Vector2, delta: float, material_type: String) -> Dictionary:
	var result = {}
	
	# Only consider horizontal speed (x component) for sliding
	var speed = abs(velocity.x)
	var direction = sign(velocity.x)
	
	# Get base friction
	var base_friction = _core.physics_calculator.get_base_friction(material_type)
	
	# Calculate effective friction (for now, just use base friction)
	var effective_friction = base_friction
	
	# Calculate deceleration
	var deceleration = _core.physics_calculator.calculate_deceleration(speed, delta, effective_friction)
	
	# Calculate new speed
	var new_speed = speed - deceleration
	
	# Check if we should stop sliding
	if _core.physics_calculator.should_stop_sliding(new_speed):
		return transition_to_stopped()
	else:
		# Continue sliding
		# Ensure Y component is always zero during sliding
		result["velocity"] = Vector2(direction * new_speed, 0.0)
		result["is_sliding"] = true

		return result
