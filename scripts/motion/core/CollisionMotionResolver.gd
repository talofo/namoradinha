class_name CollisionMotionResolver
extends RefCounted

# Reference to the motion system core
var _core = null

# The resolver used to calculate final motion values
var _resolver = null

func _init(core) -> void:
	_core = core
	_resolver = load("res://scripts/motion/MotionResolver.gd").new()
	_resolver.debug_enabled = core.debug_enabled

# Resolve collision motion (called when a collision occurs)
# collision_info: Information about the collision
# subsystems: Dictionary of registered subsystems
# Returns: The final motion vector
func resolve_collision_motion(collision_info: Dictionary, subsystems: Dictionary) -> Vector2:
	var all_modifiers = []
	
	# Collect modifiers from all subsystems
	for subsystem_name in subsystems:
		var subsystem = subsystems[subsystem_name]
		if subsystem.has_method("get_collision_modifiers"):
			var modifiers = subsystem.get_collision_modifiers(collision_info)
			
			# Collected modifiers from subsystem
			all_modifiers.append_array(modifiers)
	
	# Resolve the final motion vector
	if _resolver and _resolver.has_method("resolve_modifiers"):
		return _resolver.resolve_modifiers(all_modifiers)
	else:
		push_warning("[CollisionMotionResolver] Resolver not available or missing resolve_modifiers method")
		return Vector2.ZERO

# Resolve collision (called when a collision occurs)
# collision_info: Information about the collision
# subsystems: Dictionary of registered subsystems
# Returns: Dictionary containing collision result (velocity, has_launched, is_sliding, etc.)
func resolve_collision(collision_info: Dictionary, subsystems: Dictionary) -> Dictionary:
	var result = {}
	var material_type = collision_info.get("material", "default")
	var velocity = collision_info.get("velocity", Vector2.ZERO)
	var has_launched = collision_info.get("has_launched", false)
	var is_sliding = collision_info.get("is_sliding", false)
	
	# Handle bounce or slide based on current state
	if has_launched and velocity.y >= 0:
		# We're moving downward and have been launched, resolve collision motion (bounce or stop)

		# Get collision motion from subsystems (primarily BounceSystem)
		var collision_motion = resolve_collision_motion(collision_info, subsystems)
		result["velocity"] = collision_motion

		# Determine state based on resolved motion
		if is_zero_approx(collision_motion.y):
			# Bounce stopped, transition to slide
			result = _core.state_manager.transition_to_sliding(collision_motion)
		else:
			# Still bouncing
			result["has_launched"] = true
			result["is_sliding"] = false
			# Update max_height_y only when bouncing continues upwards
			if collision_motion.y < 0:
				result["max_height_y"] = collision_info.get("position", Vector2.ZERO).y
			else:
				pass  # No action needed when moving downward

	elif is_sliding:
		# Entity is sliding, update sliding state
		var delta = collision_info.get("delta", 0.016) # Use delta from context or fallback to ~60fps
		result = _core.state_manager.update_sliding_state(velocity, delta, material_type)
	
	return result

# Set debug mode
# enabled: Whether debug mode is enabled
func set_debug_enabled(enabled: bool) -> void:
	if _resolver:
		_resolver.debug_enabled = enabled
