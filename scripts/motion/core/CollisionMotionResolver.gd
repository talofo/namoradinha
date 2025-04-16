class_name CollisionMotionResolver
extends RefCounted

# Note: Classes are globally available via class_name

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
				# TODO: Need a robust way to get CollisionSurfaceData (e.g., from physics collision data)
				
				# Special case for BounceSystem which requires a CollisionContext object
				# This is necessary because BounceSystem uses a more structured approach
				# to collision handling compared to other subsystems
				
				# Create the incoming motion state from velocity in collision_info
				var incoming_state = IncomingMotionState.new(collision_info.get("velocity", Vector2.ZERO)) 
				
				# Get the surface normal from collision_info
				var surface_normal = collision_info.get("normal", Vector2.UP)
				var material_type = collision_info.get("material", "default")
				
				# Debug print removed
				
				# Get material properties from CollisionMaterialSystem if available
				var elasticity = 0.9  # Default fallback
				var friction = 0.1    # Default fallback
				
				var collision_material_system = _core.get_subsystem("CollisionMaterialSystem")
				if collision_material_system:
					var material_properties = collision_material_system.get_material_properties(material_type)
					elasticity = material_properties.get("bounce", elasticity)
					friction = material_properties.get("friction", friction)
					
					# Debug print removed

				# Determine surface category based on collider group
				var category = "other" # Default category
				var collider = collision_info.get("collider") 
				if is_instance_valid(collider):
					if collider.is_in_group("ground"):
						category = "ground"
						print("DEBUG RESOLVER - Collider is in 'ground' group.")
					elif collider.is_in_group("obstacles"): 
						category = "obstacle"
						print("DEBUG RESOLVER - Collider is in 'obstacles' group.")
					# Add checks for other relevant groups if necessary (e.g., "walls")
					else:
						print("DEBUG RESOLVER - Collider is not in 'ground' or 'obstacles' group. Category: 'other'.")
				else:
					push_warning("CollisionMotionResolver: Collider instance not found in collision_info! Cannot determine category.") # Corrected indentation

				# Create surface data with the normal, material properties, and category
				var surface_data = CollisionSurfaceData.new(
					surface_normal,
					collision_info.get("position", Vector2.ZERO),
					elasticity,
					friction,
					material_type,
					category # Pass the determined category
				)
				
				# Debug print removed
				
				# Get player_node from collision_info (added by PlayerCharacter)
				var player_node = collision_info.get("player_node", null)
				
				# Get or create a player bounce profile
				var player_profile = null
				
				# First check if the collision_info already has a player_bounce_profile
				if collision_info.has("player_bounce_profile") and collision_info.player_bounce_profile is PlayerBounceProfile:
					player_profile = collision_info.player_bounce_profile
					# Debug print removed
				
				# Next, try to get it from the player_node if it has a get_bounce_profile method
				elif is_instance_valid(player_node) and player_node.has_method("get_bounce_profile"):
					player_profile = player_node.get_bounce_profile()
					# Debug print removed
				
				# Next, try to get it from a profile registry in the core if available
				elif _core.has_method("get_bounce_profile_for_entity"):
					var entity_id = collision_info.get("entity_id", 0)
					player_profile = _core.get_bounce_profile_for_entity(entity_id)
					# Debug print removed
				
				# Finally, create a default profile if none was found
				if not player_profile:
					# Create a default player profile with adjusted modifiers for more horizontal movement
					player_profile = PlayerBounceProfile.new(
						1.0,                # bounciness_multiplier (default)
						0.0,                # bounce_angle_adjustment (default)
						1.0,                # gravity_scale_modifier (default)
						1.0,                # friction_interaction_modifier (default)
						1.2,                # horizontal_speed_modifier (increased)
						0.8                 # vertical_speed_modifier (decreased)
					)
					# Debug print removed
				
				# Get gravity magnitude and construct the vector
				var gravity_magnitude = _core.get_physics_config().get_gravity_for_entity("default", 1.0)
				var gravity_vector = Vector2.DOWN * gravity_magnitude
				if not is_instance_valid(player_node):
					push_error("CollisionMotionResolver: Invalid or missing 'player_node' in collision_info.")
					# Skip bounce system if player node is missing
					modifiers = [] 
				else:
					# Debug print removed
					
					# Create the context with all required data
					var context = CollisionContext.new(
						player_node,
						incoming_state,
						surface_data,
						player_profile,
						gravity_vector,
						_core.debug_enabled
					)
					
					# Debug print removed
					
					# Get modifiers from the BounceSystem
					modifiers = subsystem.get_collision_modifiers(context)
					
					# Debug print removed
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

		# Determine state based on resolved motion and BounceOutcome state
		var bounce_system = _core.get_subsystem("BounceSystem")
		var outcome_state = BounceOutcome.STATE_BOUNCING # Default if no outcome or system

		if bounce_system and bounce_system.has_method("get_last_outcome"):
			var last_outcome = bounce_system.get_last_outcome()
			if last_outcome:
				outcome_state = last_outcome.termination_state
				print("DEBUG RESOLVER - BounceOutcome state: %s" % outcome_state)
			else:
				print("DEBUG RESOLVER - BounceSystem found, but no last_outcome available.")
		else:
			print("DEBUG RESOLVER - BounceSystem not found or doesn't have get_last_outcome.")

		# Check the specific state to decide the next action
		match outcome_state:
			BounceOutcome.STATE_SLIDING:
				print("TRANSITIONING TO SLIDING - Outcome state is SLIDING")
				# Ensure Y component is zero when transitioning to sliding (Calculator might already do this, but safe)
				collision_motion.y = 0.0 
				result = _core.state_manager.transition_to_sliding(collision_motion)
				# Result from state_manager should contain velocity, has_launched=false, is_sliding=true
			BounceOutcome.STATE_STOPPED:
				print("RESOLVER - Outcome state is STOPPED. Velocity already set by calculator.")
				# Velocity should already be zero (or very small) from calculator. 
				# No state transition needed here via state_manager, but update local state flags.
				result["has_launched"] = false # No longer launched
				result["is_sliding"] = false # Not sliding
				result["velocity"] = collision_motion # Ensure we use the (likely zero) velocity from calculator
			BounceOutcome.STATE_TERMINATED_NO_SLIDE:
				print("RESOLVER - Outcome state is TERMINATED_NO_SLIDE. No sliding transition.")
				# Keep the calculated velocity from collision_motion. Player becomes airborne/falls.
				result["has_launched"] = true # Still considered 'launched' until properly grounded/stopped by other means
				result["is_sliding"] = false
				result["velocity"] = collision_motion # Ensure we use the velocity from calculator
			BounceOutcome.STATE_BOUNCING:
				# Still bouncing
				print("RESOLVER - Outcome state is BOUNCING.")
				result["has_launched"] = true
				result["is_sliding"] = false
				result["velocity"] = collision_motion # Ensure we use the velocity from calculator
				# Update max_height_y only when bouncing continues upwards
				if collision_motion.y < 0:
					result["max_height_y"] = collision_info.get("position", Vector2.ZERO).y
			_:
				push_warning("Resolver: Unhandled BounceOutcome state '%s'" % outcome_state)
				# Default fallback: treat as terminated without slide for safety?
				result["has_launched"] = true 
				result["is_sliding"] = false
				result["velocity"] = collision_motion # Use calculated velocity

	elif is_sliding:
		# Entity is sliding, update sliding state
		# Ensure Y component is zero during sliding
		velocity.y = 0.0
		# Get delta from context or use frame_rate_adjustment from physics config
		var physics_config = _core.get_physics_config()
		var default_delta = 1.0 / physics_config.frame_rate_adjustment if physics_config else 0.016
		var delta = collision_info.get("delta", default_delta)
		
		print("DEBUG: Using delta for sliding state: %.4f (from context: %s)" % [delta, collision_info.has("delta")])
		
		result = _core.state_manager.update_sliding_state(velocity, delta, material_type)
	
	return result

# Set debug mode for the modifier resolver
# enabled: Whether debug mode is enabled
func set_debug_enabled(enabled: bool) -> void:
	if _motion_modifier_resolver:
		_motion_modifier_resolver.debug_enabled = enabled
