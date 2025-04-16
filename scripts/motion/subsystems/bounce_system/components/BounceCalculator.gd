class_name BounceCalculator
extends RefCounted

# No need to preload classes defined with class_name

## Performs the stateless bounce calculation.
## Takes a CollisionContext, resolved motion profile, and physics rules, and returns a BounceOutcome.
## context: The collision context containing all input data
## resolved_profile: Dictionary of resolved motion parameters from MotionProfileResolver
## physics_rules: PhysicsConfig instance containing global rules and thresholds
func calculate(context: CollisionContext, resolved_profile: Dictionary, physics_rules: PhysicsConfig) -> BounceOutcome:
	# --- Input Extraction ---
	var motion_state = context.incoming_motion_state
	var surface = context.impact_surface_data
	var profile = context.player_bounce_profile
	var _gravity = context.current_gravity # Full gravity vector (Currently unused in calculation)
	# TODO: Revisit if gravity vector should directly influence bounce/friction/termination physics.
	
	# --- Extract Parameters from Resolved Profile and Physics Rules ---
	var _min_bounce_energy_ratio: float = resolved_profile.get("min_bounce_energy_ratio", physics_rules.min_bounce_energy_ratio)
	var min_bounce_height_threshold: float = resolved_profile.get("min_bounce_height_threshold", physics_rules.min_bounce_height_threshold)
	var min_bounce_kinetic_energy: float = resolved_profile.get("min_bounce_kinetic_energy", physics_rules.min_bounce_kinetic_energy)
	var min_stop_speed: float = resolved_profile.get("min_stop_speed", physics_rules.min_stop_speed)
	var min_slide_speed: float = resolved_profile.get("min_slide_speed", physics_rules.min_slide_speed)
	var horizontal_preservation: float = resolved_profile.get("horizontal_preservation", physics_rules.horizontal_preservation)
	
	var incoming_velocity: Vector2 = motion_state.velocity
	# --- Get Surface Normal ---
	# Use the actual surface normal from the impact data
	var surface_normal: Vector2 = surface.normal.normalized()
	
	# Debug check removed
	
	# --- Debug Setup ---
	var debug_data: BounceDebugData = null
	if context.generate_debug_data:
		debug_data = BounceDebugData.new()
		debug_data.add_note("Input Velocity: %s" % str(incoming_velocity))
		debug_data.add_note("Surface Normal: %s" % str(surface_normal))
		debug_data.add_note("Surface Elasticity: %.2f, Friction: %.2f" % [surface.elasticity, surface.friction])
		debug_data.add_note("Profile Bounciness: %.2f, FrictionMod: %.2f" % [profile.bounciness_multiplier, profile.friction_interaction_modifier])
		debug_data.add_note("Profile Angle Adjustment: %.2f (unused with flat ground)" % profile.bounce_angle_adjustment)
		debug_data.add_note("Min Bounce Height Threshold: %.2f" % min_bounce_height_threshold)
		debug_data.add_note("Min Bounce Kinetic Energy: %.2f" % min_bounce_kinetic_energy)
		debug_data.add_note("Min Slide Speed: %.2f" % min_slide_speed)
		debug_data.add_note("Min Stop Speed: %.2f" % min_stop_speed)
		debug_data.add_note("Horizontal Preservation: %.2f" % horizontal_preservation)

	# --- Core Bounce Physics ---
	# Calculate effective properties based on surface and player profile
	var effective_elasticity: float = clampf(surface.elasticity * profile.bounciness_multiplier, 0.0, 1.0)
	var effective_friction: float = maxf(surface.friction * profile.friction_interaction_modifier, 0.0)
	
	if debug_data:
		debug_data.effective_elasticity = effective_elasticity
		debug_data.effective_friction = effective_friction

	# Reflect the velocity vector across the surface normal
	# Godot's Vector2.bounce() handles reflection based on elasticity implicitly (coefficient of restitution)
	# v_out = v_in.bounce(normal) * elasticity 
	# However, let's calculate manually for clarity and modifier application:
	
	# --- Bounce Physics Using Surface Normal ---
	var calculated_velocity: Vector2 = Vector2.ZERO
	
	# 1. Decompose velocity into normal and tangential components
	var normal_component = incoming_velocity.dot(surface_normal) * surface_normal
	var tangent_component = incoming_velocity - normal_component
	
	# Store for debugging
	var normal_speed = normal_component.length()
	var tangent_speed = tangent_component.length()
	
	if debug_data:
		debug_data.add_note("Normal component: %s (speed: %.2f)" % [str(normal_component), normal_speed])
		debug_data.add_note("Tangent component: %s (speed: %.2f)" % [str(tangent_component), tangent_speed])
	
	# 2. Apply elasticity to the normal component (only if moving into the surface)
	var reflected_normal = Vector2.ZERO
	if normal_component.dot(surface_normal) < 0:
		# Moving into the surface, apply bounce
		reflected_normal = -normal_component * effective_elasticity
	else:
		# Moving away from or parallel to surface, preserve component
		if debug_data: debug_data.add_note("Grazing impact or already moving away, no normal bounce applied.")
		reflected_normal = normal_component
	
	# 3. Apply friction to the tangential component
	var friction_reduction = tangent_speed * effective_friction
	var new_tangent_speed = maxf(0.0, tangent_speed - friction_reduction)
	var scaled_tangent = Vector2.ZERO
	if tangent_speed > 0.01:
		scaled_tangent = tangent_component.normalized() * new_tangent_speed
	
	# 4. Recombine components
	calculated_velocity = reflected_normal + scaled_tangent
	
	# 5. Apply bounce angle adjustment if needed
	if !is_zero_approx(profile.bounce_angle_adjustment) and !is_zero_approx(reflected_normal.length()):
		# Only apply angle adjustment if we have a meaningful bounce
		var rotation_matrix = Transform2D().rotated(profile.bounce_angle_adjustment)
		calculated_velocity = rotation_matrix * calculated_velocity
		
		if debug_data:
			debug_data.add_note("Applied bounce angle adjustment: %.2f radians" % profile.bounce_angle_adjustment)
	
	# Special case for flat ground (Vector2.UP) to ensure identical behavior to previous implementation
	if surface_normal.is_equal_approx(Vector2.UP):
		# For flat ground, we can simplify and ensure identical results to the previous implementation
		var flat_calculated_velocity = Vector2(incoming_velocity.x, incoming_velocity.y)
		
		# Apply elasticity to Y component (only if moving downward)
		if incoming_velocity.y > 0:
			flat_calculated_velocity.y = -incoming_velocity.y * effective_elasticity
		
		# Apply friction to X component
		var flat_tangent_speed = abs(incoming_velocity.x)
		var flat_friction_reduction = flat_tangent_speed * effective_friction
		var flat_new_tangent_speed = maxf(0.0, flat_tangent_speed - flat_friction_reduction)
		flat_calculated_velocity.x = sign(incoming_velocity.x) * flat_new_tangent_speed if flat_tangent_speed > 0.01 else 0.0
		
		# For flat ground, use the simplified calculation to ensure identical behavior
		calculated_velocity = flat_calculated_velocity
		
		if debug_data:
			debug_data.add_note("Using simplified flat ground calculation for Vector2.UP normal")

	# --- Apply Profile Modifiers ---
	calculated_velocity.x *= profile.horizontal_speed_modifier
	calculated_velocity.y *= profile.vertical_speed_modifier
	
	# Apply horizontal preservation from physics rules
	calculated_velocity.x *= horizontal_preservation

	if debug_data:
		debug_data.calculated_velocity_pre_mods = calculated_velocity # Store before termination checks modify it

	# --- Determine Termination State ---
	var final_velocity = calculated_velocity
	var termination_state = BounceOutcome.STATE_BOUNCING
	
	# Get the max height and floor position from the context
	var max_height_y = context.player_node.max_height_y
	var floor_position_y = context.player_node.floor_position_y
	var _initial_bounce_position_y = context.player_node.initial_bounce_position_y
	
	# Calculate the bounce height (difference between floor and max height)
	# In Godot, Y increases downward, so floor_position_y - max_height_y gives the height
	var bounce_height = floor_position_y - max_height_y
	
	# Calculate kinetic energy (velocity^2)
	var kinetic_energy = calculated_velocity.length_squared()
	var surface_category = context.impact_surface_data.surface_category # Get the surface category
	
	# Add detailed debug prints
	print("DEBUG BOUNCE - Surface Category: %s" % surface_category)
	print("DEBUG BOUNCE - Bounce height: %.2f, Min threshold: %.2f" % [bounce_height, min_bounce_height_threshold])
	print("DEBUG BOUNCE - Kinetic energy: %.2f, Min threshold: %.2f" % [kinetic_energy, min_bounce_kinetic_energy])
	print("DEBUG BOUNCE - Current Y velocity: %.2f" % calculated_velocity.y)
	print("DEBUG BOUNCE - Max height Y: %.2f, Floor position Y: %.2f" % [max_height_y, floor_position_y])
	
	var terminate_bounce = false
	var termination_reason_str = ""

	# Apply termination logic based on surface category
	match surface_category:
		"ground", "other": # Treat "other" like ground for now
			# Original logic for surfaces that allow sliding (ground, other)
			if bounce_height < min_bounce_height_threshold:
				terminate_bounce = true
				termination_reason_str = "Bounce height %.2f < threshold %.2f" % [bounce_height, min_bounce_height_threshold]
				print("DEBUG BOUNCE - TERMINATING due to bounce height: %.2f < %.2f" % [bounce_height, min_bounce_height_threshold])
			elif kinetic_energy < min_bounce_kinetic_energy:
				terminate_bounce = true
				termination_reason_str = "Kinetic energy %.2f < threshold %.2f" % [kinetic_energy, min_bounce_kinetic_energy]
				print("DEBUG BOUNCE - TERMINATING due to kinetic energy: %.2f < %.2f" % [kinetic_energy, min_bounce_kinetic_energy])
		"obstacle":
			# Stricter logic for surfaces that DON'T allow sliding (obstacles)
			# Only terminate based on kinetic energy, ignore bounce height
			if kinetic_energy < min_bounce_kinetic_energy:
				terminate_bounce = true
				termination_reason_str = "Kinetic energy %.2f < threshold %.2f (Obstacle - No Sliding)" % [kinetic_energy, min_bounce_kinetic_energy]
		_: # Default case if category is unknown
			push_warning("BounceCalculator: Unknown surface category '%s'. Applying default ground logic." % surface_category)
			# Apply ground logic as a fallback
			if bounce_height < min_bounce_height_threshold:
				terminate_bounce = true
				termination_reason_str = "Bounce height %.2f < threshold %.2f (Unknown Category)" % [bounce_height, min_bounce_height_threshold]
			elif kinetic_energy < min_bounce_kinetic_energy:
				terminate_bounce = true
				termination_reason_str = "Kinetic energy %.2f < threshold %.2f (Unknown Category)" % [kinetic_energy, min_bounce_kinetic_energy]

	if terminate_bounce:
		print("DEBUG BOUNCE - TERMINATING: %s" % termination_reason_str)
		
		match surface_category:
			"ground", "other":
				# Check if we have enough speed to slide
				var horizontal_speed = abs(calculated_velocity.x)
				
				# First check if we have enough speed to slide
				if horizontal_speed >= min_slide_speed:
					# We have enough speed to slide, now check if it's above the stop threshold
					if horizontal_speed >= min_stop_speed:
						# Transition to sliding for ground/other surfaces
						termination_state = BounceOutcome.STATE_SLIDING
						final_velocity = calculated_velocity # Keep calculated velocity for sliding start
						if debug_data:
							debug_data.termination_reason = termination_reason_str
							debug_data.add_note("Entering SLIDING state. Horizontal speed %.2f >= min_slide_speed %.2f" % [horizontal_speed, min_slide_speed])
						
						print("DEBUG BOUNCE - Entering SLIDING state. Speed: %.2f" % horizontal_speed)
					else:
						# Speed is enough to slide but below stop threshold, still stop
						termination_state = BounceOutcome.STATE_STOPPED
						final_velocity = Vector2.ZERO # Force stop
						if debug_data:
							debug_data.termination_reason = termination_reason_str + " | Horizontal speed %.2f < min_stop_speed %.2f" % [horizontal_speed, min_stop_speed]
							debug_data.add_note("Entering STOPPED state (below stop threshold).")
						
						print("DEBUG BOUNCE - Speed above slide threshold but below stop threshold: %.2f < %.2f" % [horizontal_speed, min_stop_speed])
				else:
					# Not enough speed to slide, go directly to stopped
					termination_state = BounceOutcome.STATE_STOPPED
					final_velocity = Vector2.ZERO # Force stop
					if debug_data:
						debug_data.termination_reason = termination_reason_str + " | Horizontal speed %.2f < min_slide_speed %.2f" % [horizontal_speed, min_slide_speed]
						debug_data.add_note("Entering STOPPED state (insufficient slide speed).")
					
					print("DEBUG BOUNCE - Not enough speed to slide: %.2f < %.2f" % [horizontal_speed, min_slide_speed])
			"obstacle":
				# Surface doesn't allow sliding, transition to a non-sliding terminated state
				termination_state = BounceOutcome.STATE_TERMINATED_NO_SLIDE # Use the new state
				final_velocity = calculated_velocity # Keep velocity, gravity will apply next frame
				if debug_data:
					debug_data.termination_reason = termination_reason_str
					debug_data.add_note("Entering TERMINATED_NO_SLIDE state.")
			_: # Fallback for unknown category
				termination_state = BounceOutcome.STATE_SLIDING # Default to sliding
				final_velocity = calculated_velocity 
				if debug_data:
					debug_data.termination_reason = termination_reason_str + " (Unknown Category - Defaulting to Sliding)"
					debug_data.add_note("Entering SLIDING state (Fallback).")

	else:
		# Sufficient energy/height to continue bouncing
		termination_state = BounceOutcome.STATE_BOUNCING
		final_velocity = calculated_velocity
		if debug_data: debug_data.add_note("Continuing BOUNCING state.")

	# --- Create Outcome ---
	# Ensure BounceOutcome handles the new state STATE_TERMINATED_NO_SLIDE
	var outcome = BounceOutcome.new(final_velocity, termination_state, debug_data)
	
	return outcome
