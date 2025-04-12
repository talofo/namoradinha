class_name CollisionMotionResolver
extends RefCounted

# Note: Preloads removed as classes are globally available via class_name

# Reference to the motion system core
var _core = null

# The resolver used to calculate final motion values (for dynamic modifiers)
var _motion_modifier_resolver = null

func _init(core) -> void:
	_core = core
	# Load the renamed MotionModifierResolver
	var script = load("res://scripts/motion/MotionModifierResolver.gd")
	if script:
		_motion_modifier_resolver = script.new()
		_motion_modifier_resolver.debug_enabled = core.debug_enabled
	else:
		push_error("CollisionMotionResolver: Failed to load MotionModifierResolver script!")

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
			var modifiers = []
			if subsystem is BounceSystem:
				# Construct CollisionContext for BounceSystem
				# ASSUMPTION: collision_info contains all necessary raw data
				# TODO: Need a robust way to get PlayerBounceProfile (e.g., from entity data via _core)
				# TODO: Need a robust way to get ImpactSurfaceData (e.g., from physics collision data)
				
				# Placeholder data - this needs proper implementation later
				var incoming_state = IncomingMotionState.new(collision_info.get("velocity", Vector2.ZERO)) 
				var surface_data = ImpactSurfaceData.new(collision_info.get("normal", Vector2.UP)) 
				var player_profile = PlayerBounceProfile.new() # Needs real data
				# Get gravity magnitude and construct the vector
				var gravity_magnitude = _core.get_physics_config().get_gravity_for_entity("default", 1.0) # Example access
				var gravity_vector = Vector2.DOWN * gravity_magnitude
				
				# Get player_node from collision_info (ASSUMPTION: PlayerCharacter adds this)
				var player_node = collision_info.get("player_node", null) 
				if not is_instance_valid(player_node):
					push_error("CollisionMotionResolver: Invalid or missing 'player_node' in collision_info.")
					# Skip bounce system if player node is missing
					modifiers = [] 
				else:
					var context = CollisionContext.new(
						player_node, # Pass player_node
						incoming_state,
						surface_data,
						player_profile,
						gravity_vector, # Pass the Vector2
						_core.debug_enabled # Pass debug flag
					)
					modifiers = subsystem.get_collision_modifiers(context)
			else:
				# Other subsystems still receive the raw dictionary
				modifiers = subsystem.get_collision_modifiers(collision_info)
			
			# Collected modifiers from subsystem
			all_modifiers.append_array(modifiers)
	
	# Resolve the final motion vector using the modifier resolver
	if _motion_modifier_resolver and _motion_modifier_resolver.has_method("resolve_modifiers"):
		return _motion_modifier_resolver.resolve_modifiers(all_modifiers)
	else:
		push_warning("[CollisionMotionResolver] MotionModifierResolver not available or missing resolve_modifiers method")
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
			# Ensure Y component is zero when transitioning to sliding
			collision_motion.y = 0.0
			result = _core.state_manager.transition_to_sliding(collision_motion)
		else:
			# Still bouncing
			result["has_launched"] = true
			result["is_sliding"] = false
			# Update max_height_y only when bouncing continues upwards
			if collision_motion.y < 0:
				result["max_height_y"] = collision_info.get("position", Vector2.ZERO).y
			else:
				pass # Restore redundant else: pass block
				
	elif is_sliding:
		# Entity is sliding, update sliding state
		# Ensure Y component is zero during sliding
		velocity.y = 0.0
		var delta = collision_info.get("delta", 0.016) # Use delta from context or fallback to ~60fps
		result = _core.state_manager.update_sliding_state(velocity, delta, material_type)
	
	return result

# Set debug mode for the modifier resolver
# enabled: Whether debug mode is enabled
func set_debug_enabled(enabled: bool) -> void:
	if _motion_modifier_resolver:
		_motion_modifier_resolver.debug_enabled = enabled
