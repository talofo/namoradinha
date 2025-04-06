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
	
	# Apply gravity if entity is launched
	if context.has("has_launched") and context.get("has_launched"):
		var velocity = context.get("velocity", Vector2.ZERO)
		var delta = context.get("delta", 0.01) # Fallback to 0.01 if no delta
		var entity_id = context.get("entity_id", 0)
		
		ErrorHandler.debug("MotionStateManager", "Entity " + str(entity_id) + " BEFORE gravity - velocity=" + str(velocity) + " (magnitude=" + str(velocity.length()) + ")")
		
		# Get appropriate gravity based on entity type and mass
		var entity_type = context.get("entity_type", "default")
		var mass = context.get("mass", _core.physics_config.default_mass if _core.physics_config else 1.0)
		
		# Apply gravity
		velocity = _core.physics_calculator.apply_gravity(velocity, delta, entity_type, mass)
		result["velocity"] = velocity
		
		ErrorHandler.debug("MotionStateManager", "Entity " + str(entity_id) + " AFTER gravity - velocity=" + str(velocity) + " (magnitude=" + str(velocity.length()) + ")")
	
	# Get continuous motion modifiers
	var motion_delta = _core.resolve_continuous_motion(
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
	
	# Use the entity_id directly from context for the final debug message
	ErrorHandler.debug("MotionStateManager", "Entity " + str(context.get("entity_id", 0)) + " FINAL frame motion velocity=" + str(result["velocity"]) + " (magnitude=" + str(result["velocity"].length()) + ")")
	
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
	
	ErrorHandler.info("MotionStateManager", "Bounce stopped (y-velocity near zero). Transitioning to slide with velocity_x=" + str(preserved_x_velocity))
	
	return result

# Handle state transition from sliding to stopped
# Returns: Dictionary with updated state information
func transition_to_stopped() -> Dictionary:
	var result = {}
	
	result["velocity"] = Vector2.ZERO
	result["is_sliding"] = false
	result["just_stopped_sliding"] = true # Flag that we just stopped
	
	ErrorHandler.info("MotionStateManager", "Sliding stopped")
	
	return result

# Update sliding state
# velocity: Current velocity
# delta: Time since last frame
# material_type: Type of material being slid on
# Returns: Dictionary with updated state information
func update_sliding_state(velocity: Vector2, delta: float, material_type: String) -> Dictionary:
	var result = {}
	
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
		result["velocity"] = Vector2(direction * new_speed, 0.0)
		result["is_sliding"] = true
		
		ErrorHandler.debug("MotionStateManager", "Sliding with speed=" + str(new_speed) + 
			", deceleration=" + str(deceleration) + 
			", effective_friction=" + str(effective_friction))
		
		return result
