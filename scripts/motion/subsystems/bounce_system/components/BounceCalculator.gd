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
	var horizontal_preservation: float = resolved_profile.get("horizontal_preservation", physics_rules.horizontal_preservation)
	
	var incoming_velocity: Vector2 = motion_state.velocity
	# --- Get Surface Normal ---
	# Use the actual surface normal from the impact data
	var surface_normal: Vector2 = surface.normal.normalized()
	
	# Debug check to ensure we're getting a valid normal
	if Engine.is_editor_hint() or OS.is_debug_build():
		print("[DEBUG] BounceCalculator: Using surface normal: ", surface_normal)
		if surface_normal.is_equal_approx(Vector2.UP):
			print("[DEBUG] BounceCalculator: Surface is flat (normal = UP)")
	
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
	
	# Print debug information (only in debug mode)
	if Engine.is_editor_hint() or OS.is_debug_build():
		print("[DEBUG] BounceCalculator: floor_position_y=", floor_position_y, ", max_height_y=", max_height_y)
		print("[DEBUG] BounceCalculator: bounce_height=", bounce_height, ", threshold=", min_bounce_height_threshold)
		print("[DEBUG] BounceCalculator: incoming_velocity=", incoming_velocity)
		print("[DEBUG] BounceCalculator: effective_elasticity=", effective_elasticity)
		print("[DEBUG] BounceCalculator: calculated_velocity=", calculated_velocity)
		print("[DEBUG] BounceCalculator: kinetic_energy=", kinetic_energy, ", threshold=", min_bounce_kinetic_energy)
	
	# Check if bounce height is below threshold or kinetic energy is too low
	if Engine.is_editor_hint() or OS.is_debug_build():
		print("[DEBUG] BounceCalculator: Checking termination conditions...")
		print("[DEBUG] BounceCalculator: bounce_height < threshold: ", bounce_height, " < ", min_bounce_height_threshold)
		print("[DEBUG] BounceCalculator: kinetic_energy < threshold: ", kinetic_energy, " < ", min_bounce_kinetic_energy)
	
	# Transition to sliding if bounce height is too small or kinetic energy is too low
	if bounce_height < min_bounce_height_threshold or kinetic_energy < min_bounce_kinetic_energy:
		# Bounce height too small, transition to sliding
		termination_state = BounceOutcome.STATE_SLIDING
		# Keep the calculated velocity which includes slope influence
		final_velocity = calculated_velocity # Ensure we use the calculated velocity for sliding
		
		if debug_data:
			if bounce_height < min_bounce_height_threshold:
				debug_data.termination_reason = "Bounce height %.2f < threshold %.2f" % [
					bounce_height, min_bounce_height_threshold]
			else:
				debug_data.termination_reason = "Kinetic energy %.2f < threshold %.2f" % [
					kinetic_energy, min_bounce_kinetic_energy]
			debug_data.add_note("Entering SLIDING state.")
			
		if Engine.is_editor_hint() or OS.is_debug_build():
			print("[DEBUG] BounceCalculator: Transitioning to SLIDING state. Reason: Bounce height too small")

		# Check if sliding speed (now just horizontal speed) is also too low -> STOPPED
		var sliding_speed = abs(final_velocity.x) # Check speed *before* potentially setting to zero
		if sliding_speed < min_stop_speed:
			termination_state = BounceOutcome.STATE_STOPPED
			if debug_data:
				# Append to existing reason if it exists
				if debug_data.termination_reason:
					debug_data.termination_reason += " | Sliding speed %.2f < threshold %.2f" % [sliding_speed, min_stop_speed]
				else: # Should not happen based on logic, but safe fallback
					debug_data.termination_reason = "Sliding speed %.2f < threshold %.2f" % [sliding_speed, min_stop_speed]
				debug_data.add_note("Entering STOPPED state.")
			final_velocity = Vector2.ZERO # Force stop *after* logging
	else:
		# Sufficient energy to bounce
		final_velocity = calculated_velocity # Keep the calculated bounce velocity
		if Engine.is_editor_hint() or OS.is_debug_build():
			print("[DEBUG] BounceCalculator: Continuing to bounce. Height: ", bounce_height)

	# --- Create Outcome ---
	var outcome = BounceOutcome.new(final_velocity, termination_state, debug_data)
	
	return outcome
