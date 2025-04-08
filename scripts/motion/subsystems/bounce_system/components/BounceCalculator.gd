class_name BounceCalculator
extends RefCounted

# No need to preload classes defined with class_name

# --- Constants ---
# Minimum ratio of normal velocity to maintain after bounce (0.0-1.0)
const MIN_BOUNCE_ENERGY_RATIO: float = 0.3
# Minimum absolute normal speed required to continue bouncing after impact.
const MIN_ABSOLUTE_BOUNCE_NORMAL_SPEED: float = 5.0
# Minimum speed below which the entity might transition from sliding to stopped.
const MIN_STOP_SPEED: float = 10.0

## Performs the stateless bounce calculation.
## Takes a CollisionContext and returns a BounceOutcome.
func calculate(context: CollisionContext) -> BounceOutcome:
	# --- Input Extraction ---
	var motion_state = context.incoming_motion_state
	var surface = context.impact_surface_data
	var profile = context.player_bounce_profile
	var _gravity = context.current_gravity # Full gravity vector (Currently unused in calculation)
	# TODO: Revisit if gravity vector should directly influence bounce/friction/termination physics.
	
	var incoming_velocity: Vector2 = motion_state.velocity
	# --- Assume Flat Surface ---
	# We are explicitly told the surface will always be flat ground.
	# Therefore, the normal is always UP. We ignore the reported surface.normal for bounce calculation.
	var surface_normal: Vector2 = Vector2.UP 
	
	# --- Debug Setup ---
	var debug_data: BounceDebugData = null
	if context.generate_debug_data:
		debug_data = BounceDebugData.new()
		debug_data.add_note("Input Velocity: %s" % str(incoming_velocity))
		debug_data.add_note("Surface Normal: %s" % str(surface_normal))
		debug_data.add_note("Surface Elasticity: %.2f, Friction: %.2f" % [surface.elasticity, surface.friction])
		debug_data.add_note("Profile Bounciness: %.2f, FrictionMod: %.2f" % [profile.bounciness_multiplier, profile.friction_interaction_modifier])

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
	
	# --- Simplified Bounce Physics (Assuming Flat Surface Normal = Vector2.UP) ---
	var calculated_velocity: Vector2 = incoming_velocity

	# 1. Apply elasticity to the Y component (normal component for flat ground)
	# Only apply if moving downwards (velocity.y > 0 in Godot 2D)
	if incoming_velocity.y > 0:
		calculated_velocity.y = -incoming_velocity.y * effective_elasticity
	else:
		# If already moving up, don't apply bounce elasticity (e.g., grazing angle)
		if debug_data: debug_data.add_note("Grazing impact or already moving up, no Y-velocity bounce applied.")
		pass 

	# 2. Apply friction to the X component (tangent component for flat ground)
	# Simple model: Reduce horizontal speed based on friction.
	var tangent_speed = abs(incoming_velocity.x)
	var friction_reduction = tangent_speed * effective_friction # Simplified reduction factor
	var new_tangent_speed = maxf(0.0, tangent_speed - friction_reduction)
	calculated_velocity.x = sign(incoming_velocity.x) * new_tangent_speed if tangent_speed > 0.01 else 0.0

	# --- Apply Profile Modifiers (Directly to X/Y components) ---
	calculated_velocity.x *= profile.horizontal_speed_modifier
	calculated_velocity.y *= profile.vertical_speed_modifier
	# Note: bounce_angle_adjustment is ignored in this simplified model

	if debug_data:
		debug_data.calculated_velocity_pre_mods = calculated_velocity # Store before termination checks modify it

	# --- Determine Termination State ---
	var final_velocity = calculated_velocity
	var termination_state = BounceOutcome.STATE_BOUNCING
	
	# Check bounce threshold using Y-velocity (normal component for flat ground)
	var velocity_away_from_surface = abs(calculated_velocity.y) # Speed moving away vertically
	var incoming_normal_speed = abs(incoming_velocity.y) # Speed impacting vertically

	# Avoid division by zero if incoming normal speed is negligible
	var bounce_ratio = 0.0
	if incoming_normal_speed > 0.01: # Add a small epsilon check
		bounce_ratio = velocity_away_from_surface / incoming_normal_speed

	# Check if bounce energy ratio OR absolute normal speed is below threshold
	if bounce_ratio < MIN_BOUNCE_ENERGY_RATIO or velocity_away_from_surface < MIN_ABSOLUTE_BOUNCE_NORMAL_SPEED:
		# Not enough energy retained OR absolute speed too low to bounce significantly
		termination_state = BounceOutcome.STATE_SLIDING
		# When sliding, kill the vertical velocity
		final_velocity.y = 0.0 
		
		if debug_data:
			if bounce_ratio < MIN_BOUNCE_ENERGY_RATIO:
				debug_data.termination_reason = "Vertical velocity ratio %.2f < threshold %.2f (vel_out: %.2f / vel_in: %.2f)" % [
					bounce_ratio, MIN_BOUNCE_ENERGY_RATIO, velocity_away_from_surface, incoming_normal_speed]
			else: # Must be the absolute speed check that failed
				debug_data.termination_reason = "Absolute vertical speed %.2f < threshold %.2f" % [
					velocity_away_from_surface, MIN_ABSOLUTE_BOUNCE_NORMAL_SPEED]
			debug_data.add_note("Entering SLIDING state.")

		# Check if sliding speed (now just horizontal speed) is also too low -> STOPPED
		var sliding_speed = abs(final_velocity.x) # Check speed *before* potentially setting to zero
		if sliding_speed < MIN_STOP_SPEED:
			termination_state = BounceOutcome.STATE_STOPPED
			if debug_data:
				# Append to existing reason if it exists
				if debug_data.termination_reason:
					debug_data.termination_reason += " | Sliding speed %.2f < threshold %.2f" % [sliding_speed, MIN_STOP_SPEED]
				else: # Should not happen based on logic, but safe fallback
					debug_data.termination_reason = "Sliding speed %.2f < threshold %.2f" % [sliding_speed, MIN_STOP_SPEED]
				debug_data.add_note("Entering STOPPED state.")
			final_velocity = Vector2.ZERO # Force stop *after* logging
	else:
		# Sufficient energy to bounce
		final_velocity = calculated_velocity # Keep the calculated bounce velocity

	# --- Create Outcome ---
	var outcome = BounceOutcome.new(final_velocity, termination_state, debug_data)
	
	return outcome
