class_name BounceCalculator
extends RefCounted

# No need to preload classes defined with class_name

# --- Constants ---
# Minimum vertical velocity (relative to surface normal) required to initiate/continue a bounce.
# Needs tuning based on gravity and desired feel.
const MIN_BOUNCE_VELOCITY_NORMAL: float = 50.0 
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
	var surface_normal: Vector2 = surface.normal.normalized() # Ensure it's normalized
	
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
	
	# 1. Decompose velocity into normal (perpendicular) and tangent (parallel) components
	var velocity_normal_component: Vector2 = surface_normal * incoming_velocity.dot(surface_normal)
	var velocity_tangent_component: Vector2 = incoming_velocity - velocity_normal_component
	
	# 2. Apply elasticity to the normal component (reversing its direction)
	# Only apply bounce if impacting *into* the surface (dot product < 0)
	var new_velocity_normal_component: Vector2 = velocity_normal_component
	if velocity_normal_component.dot(surface_normal) < 0:
		new_velocity_normal_component = -velocity_normal_component * effective_elasticity
	else:
		# If already moving away from surface, don't apply bounce elasticity
		# This might happen on grazing angles or multi-collisions in one frame
		if debug_data: debug_data.add_note("Grazing impact, no normal velocity bounce applied.")
		pass 

	# 3. Apply friction to the tangent component (opposing tangential motion)
	# Simple model: Reduce tangential speed based on friction.
	# A more complex model would involve normal force magnitude, but let's keep it simpler first.
	# We can use slide() logic conceptually: reduce speed, don't reverse direction unless friction is extreme.
	var tangent_speed = velocity_tangent_component.length()
	var friction_reduction = tangent_speed * effective_friction # Simplified reduction factor
	var new_tangent_speed = maxf(0.0, tangent_speed - friction_reduction) 
	
	var new_velocity_tangent_component: Vector2 = velocity_tangent_component.normalized() * new_tangent_speed if tangent_speed > 0.01 else Vector2.ZERO

	# --- Apply Profile Modifiers ---
	# Note: Modifiers applied *after* basic physics reflection/friction
	
	# Apply speed modifiers
	new_velocity_normal_component *= profile.vertical_speed_modifier # Assuming normal is mostly vertical
	new_velocity_tangent_component *= profile.horizontal_speed_modifier # Assuming tangent is mostly horizontal
	
	# Apply angle adjustment (rotate the combined vector) - complex, might be better handled by boost system?
	# Skipping angle adjustment for now for simplicity, as it can be tricky to define consistently.
	# If needed: var combined_velocity = new_velocity_normal_component + new_velocity_tangent_component
	#           combined_velocity = combined_velocity.rotated(profile.bounce_angle_adjustment)
	#           Then potentially re-decompose if needed for termination checks.

	# --- Recompose Final Velocity ---
	var calculated_velocity = new_velocity_normal_component + new_velocity_tangent_component
	
	if debug_data:
		debug_data.calculated_velocity_pre_mods = calculated_velocity # Store before termination checks modify it

	# --- Determine Termination State ---
	var final_velocity = calculated_velocity
	var termination_state = BounceOutcome.STATE_BOUNCING
	
	# Check vertical bounce threshold (velocity component moving away from the surface normal)
	var velocity_away_from_surface = final_velocity.dot(surface_normal)
	
	if velocity_away_from_surface < MIN_BOUNCE_VELOCITY_NORMAL:
		# Not enough energy to bounce significantly away from the surface
		termination_state = BounceOutcome.STATE_SLIDING # Use global class name
		# When sliding, kill the velocity component directly into the normal
		final_velocity = final_velocity - surface_normal * final_velocity.dot(surface_normal)
		if debug_data: 
			debug_data.termination_reason = "Normal velocity %.2f < threshold %.2f" % [velocity_away_from_surface, MIN_BOUNCE_VELOCITY_NORMAL]
			debug_data.add_note("Entering SLIDING state.") # Corrected indentation
		
		# Check if sliding speed is also too low -> STOPPED
		if final_velocity.length() < MIN_STOP_SPEED:
			termination_state = BounceOutcome.STATE_STOPPED # Use global class name
			final_velocity = Vector2.ZERO # Force stop
			if debug_data: 
				debug_data.termination_reason += " | Sliding speed %.2f < threshold %.2f" % [final_velocity.length(), MIN_STOP_SPEED]
				debug_data.add_note("Entering STOPPED state.")
	
	# --- Create Outcome ---
	var outcome = BounceOutcome.new(final_velocity, termination_state, debug_data)
	
	return outcome
