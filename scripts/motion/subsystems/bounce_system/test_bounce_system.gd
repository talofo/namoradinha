# Test script adapted to run attached to a Node in a scene
extends Node

# --- Test Framework Setup (Basic Assertions) ---
# Simplified runner - removed run_test, test_count, pass_count for now

func assert_true(condition: bool, message: String = ""):
	if not condition:
		printerr("    Assertion Failed: ", message if not message.is_empty() else "Condition is false")
		return false
	return true

func assert_false(condition: bool, message: String = ""):
	if condition:
		printerr("    Assertion Failed: ", message if not message.is_empty() else "Condition is true")
		return false
	return true

func assert_eq(val1, val2, message: String = ""):
	if val1 != val2:
		printerr("    Assertion Failed: Expected '%s' == '%s'. %s" % [str(val1), str(val2), message])
		return false
	return true

func assert_ne(val1, val2, message: String = ""):
	if val1 == val2:
		printerr("    Assertion Failed: Expected '%s' != '%s'. %s" % [str(val1), str(val2), message])
		return false
	return true

func assert_vector2_approx_eq(v1: Vector2, v2: Vector2, tolerance: float = 0.001, message: String = ""):
	# Manual approximate comparison using tolerance
	if (v1 - v2).length_squared() >= tolerance * tolerance:
		printerr("    Assertion Failed: Expected Vector2 %s approx == %s (tolerance: %f). Difference: %s. %s" % [str(v1), str(v2), tolerance, str(v1-v2), message])
		return false
	return true

# --- Test Dependencies ---
# Note: Preloads removed as classes are globally available via class_name
# const BounceSystem = preload(...) # Not needed
# const CollisionContext = preload(...) # Not needed
# const IncomingMotionState = preload(...) # Not needed
# Note: Classes are globally available via class_name
# const PlayerBounceProfile = preload(...) # Not needed
# const BounceOutcome = preload(...) # Not needed
# const MotionModifier = preload(...) # Not needed

# --- Test Subject ---
var bounce_system: BounceSystem # Use the correct global class name
var MIN_STOP_SPEED = 10.0 # Define the constant here since we can't access it from BounceCalculator

# --- Test Suite ---
func _ready(): # Changed from _init to run when node is ready
	print("\n--- Testing BounceSystem (In-Scene) ---")
	bounce_system = BounceSystem.new() # Instantiate using the correct global class name
	var all_passed = true

	# --- Individual Tests (Direct Calls) ---
	print("Running test: test_basic_first_bounce_flat_ground")
	if not test_basic_first_bounce_flat_ground():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_bounce_with_high_bounciness")
	if not test_bounce_with_high_bounciness():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	# Add more tests here...
	# print("Running test: test_bounce_with_friction") # Add friction test later if needed
	print("Running test: test_termination_low_velocity")
	if not test_termination_low_velocity():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_full_sequence_simulation") 
	if not test_full_sequence_simulation():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")

	# --- Summary ---
	print("\n--- Test Summary ---")
	if all_passed:
		print("All tests passed!")
	else:
		print("Some tests failed.")
	print("--------------------\n")

	# No quit() needed when running in editor/scene
	# quit(0 if all_passed else 1) 

# --- Test Cases ---

func test_basic_first_bounce_flat_ground() -> bool:
	var success = true
	var modifiers = [] # Declare variable beforehand
	
	# Arrange: Define the collision context
	var incoming_state = IncomingMotionState.new(Vector2(300, 600)) # Moving right and strongly downwards
	var surface_data = CollisionSurfaceData.new(
		Vector2.UP, # Normal pointing straight up
		Vector2(100, 500), # Collision point
		0.6, # Elasticity
		0.1  # Friction
	)
	var player_profile = PlayerBounceProfile.new() # Default profile
	var gravity = Vector2.DOWN * 980.0
	
	# Create a mock player node for testing
	var mock_player = Node.new()
	mock_player.max_height_y = 0
	mock_player.floor_position_y = 500
	mock_player.initial_bounce_position_y = 500
	
	var context = CollisionContext.new(
		mock_player,
		incoming_state,
		surface_data,
		player_profile,
		gravity,
		true # Generate debug data
	)
	
	
	# Act: Call the system's modifier function directly with the context object
	# Assign to the pre-declared variable
	modifiers = bounce_system.get_collision_modifiers(context) 
	
	# Assert: Check the outcome
	# Check size using the stored result to avoid redundant call/debug print
	success = assert_eq(modifiers.size(), 1, "Should return exactly one modifier.") and success
	if success: # No need to check size again
		var mod: MotionModifier = modifiers[0]
		success = assert_eq(mod.source, "BounceSystem", "Modifier source should be BounceSystem.") and success
		success = assert_eq(mod.type, "velocity", "Modifier type should be velocity.") and success
		success = assert_false(mod.is_additive, "Modifier should replace velocity.") and success
		
		# Expected outcome calculation (manual for verification):
		# Normal velocity = (300, 600) dot (0, -1) = -600 (into surface)
		# Tangent velocity = (300, 600) - (0, -1)*(-600) = (300, 600) - (0, 600) = (300, 0)
		# New normal velocity = -(-600) * 0.6 (elasticity) = 360 (upwards) -> Vector (0, -360)
		# New tangent velocity = (300, 0) * (1 - 0.1 friction) = (270, 0) (simplified friction)
		# Expected velocity = (270, -360)
		var expected_velocity = Vector2(270, -360) 
		# Note: The calculator uses maxf(0, speed - speed*friction), so 300 - 300*0.1 = 270. Matches.
		
		success = assert_vector2_approx_eq(mod.vector, expected_velocity, 0.01, "Bounce velocity calculation incorrect.") and success
	
	return success

# --- Placeholder for more tests ---

func test_bounce_with_high_bounciness() -> bool: 
	var success = true
	
	# Arrange: Similar context, but higher bounciness multiplier
	var incoming_state = IncomingMotionState.new(Vector2(300, 600)) 
	var surface_data = CollisionSurfaceData.new(Vector2.UP, Vector2(100, 500), 0.6, 0.1)
	# Increase bounciness via profile - Use positional argument for constructor
	var player_profile = PlayerBounceProfile.new(1.5) 
	var gravity = Vector2.DOWN * 980.0
	
	# Create a mock player node for testing
	var mock_player = Node.new()
	mock_player.max_height_y = 0
	mock_player.floor_position_y = 500
	mock_player.initial_bounce_position_y = 500
	
	var context = CollisionContext.new(
		mock_player,
		incoming_state,
		surface_data,
		player_profile,
		gravity,
		true
	)
	
	# Act: Call the system's modifier function directly with the context object
	var result_array = bounce_system.get_collision_modifiers(context) # Keep isolated call for now
	var modifiers = result_array # Assign on a new line, no type hint
	
	# Assert: Check the outcome
	success = assert_eq(modifiers.size(), 1, "Should return exactly one modifier.") and success
	if modifiers.size() == 1:
		var mod: MotionModifier = modifiers[0]
		
		# Expected outcome calculation:
		# Effective elasticity = 0.6 * 1.5 = 0.9
		# Normal velocity = -600 (into surface)
		# New normal velocity = -(-600) * 0.9 = 540 (upwards) -> Vector (0, -540)
		# Tangent velocity = (300, 0)
		# New tangent velocity = (270, 0) (friction 0.1 applied)
		# Expected velocity = (270, -540)
		var expected_velocity = Vector2(270, -540) 
		
		success = assert_vector2_approx_eq(mod.vector, expected_velocity, 0.01, "High bounciness calculation incorrect.") and success
	
	return success

# func test_bounce_with_friction() -> bool: return false

func test_termination_low_velocity() -> bool:
	var success = true
	
	# Arrange: Low incoming velocity, below bounce threshold
	# MIN_BOUNCE_VELOCITY_NORMAL is 50.0 in BounceCalculator
	var incoming_state = IncomingMotionState.new(Vector2(20, 40)) # Low speed, downwards
	var surface_data = CollisionSurfaceData.new(Vector2.UP, Vector2(100, 500), 0.6, 0.1)
	var player_profile = PlayerBounceProfile.new() 
	var gravity = Vector2.DOWN * 980.0
	
	# Create a mock player node for testing
	var mock_player = Node.new()
	mock_player.max_height_y = 0
	mock_player.floor_position_y = 500
	mock_player.initial_bounce_position_y = 500
	
	var context = CollisionContext.new(
		mock_player,
		incoming_state,
		surface_data,
		player_profile,
		gravity,
		true
	)
	
	# Act
	var result_array = bounce_system.get_collision_modifiers(context)
	var modifiers = result_array 
	
	# Assert
	success = assert_eq(modifiers.size(), 1, "Termination should still produce one velocity modifier.") and success
	if modifiers.size() == 1:
		var mod: MotionModifier = modifiers[0]
		
		# Expected outcome: Termination -> SLIDING or STOPPED
		# Calculator logic: If velocity_away_from_surface < MIN_BOUNCE_VELOCITY_NORMAL, enter SLIDING.
		# velocity_away_from_surface = final_velocity.dot(surface_normal)
		# Initial normal vel = 40 downwards. Reflected = -40 * 0.6 = -24 (upwards). Vector = (0, -24)
		# Initial tangent vel = (20, 0). Friction reduces it: 20 - 20*0.1 = 18. Vector = (18, 0)
		# Calculated velocity = (18, -24). 
		# velocity_away_from_surface = (18, -24).dot(0, -1) = 24.
		# 24 < MIN_BOUNCE_VELOCITY_NORMAL (50.0) -> True. Enter SLIDING.
		# Sliding velocity = calculated_velocity - normal * calculated_velocity.dot(normal)
		# Sliding velocity = (18, -24) - (0, -1) * ((18, -24).dot(0, -1))
		# Sliding velocity = (18, -24) - (0, -1) * 24 = (18, -24) - (0, -24) = (18, 0)
		# Check STOP threshold: Sliding speed = 18. MIN_STOP_SPEED = 10. 18 > 10. So, SLIDING.
		var expected_velocity = Vector2(18, 0) 
		
		success = assert_vector2_approx_eq(mod.vector, expected_velocity, 0.01, "Sliding velocity calculation incorrect.") and success
		
		# We also need to check the outcome state if BounceSystem exposed it, 
		# but currently it only returns the modifier. We infer state from velocity.
		# Ideally, BounceSystem would return the BounceOutcome object directly.
		# For now, we check if Y velocity is zero (or very close to it).
		success = assert_true(abs(mod.vector.y) < 0.01, "Velocity Y should be near zero for sliding/stopped state.") and success

	return success

func test_full_sequence_simulation() -> bool:
	var success = true
	
	# Arrange: Initial launch state
	var current_velocity = Vector2(400, -800) # Strong launch up and right
	var current_position = Vector2(0, 500)    # Start above ground
	var gravity_value = 1500.0                # Slightly higher gravity for faster test
	var gravity = Vector2.DOWN * gravity_value
	var delta_time = 0.05                     # Simulate physics step time
	var max_steps = 100                       # Prevent infinite loops
	var step_count = 0

	var surface_data = CollisionSurfaceData.new(Vector2.UP, Vector2.ZERO, 0.7, 0.1) # Bouncy ground
	var player_profile = PlayerBounceProfile.new()
	
	print("    Simulating sequence: Launch -> Bounce(s) -> Slide/Stop")
	print("    Initial Velocity: ", current_velocity)

	# Act: Simulate physics steps and bounces
	while step_count < max_steps:
		step_count += 1
		
		# 1. Apply gravity and update position (simplified Euler integration)
		current_velocity += gravity * delta_time
		current_position += current_velocity * delta_time
		
		# 2. Check for ground collision (simplified: position.y >= ground level)
		var ground_level = 500.0 # Assume flat ground at y=500
		if current_position.y >= ground_level:
			print("      Step %d: Collision at Pos: %s, Vel: %s" % [step_count, str(current_position.round()), str(current_velocity.round())])
			
			# Correct position to be exactly on ground
			current_position.y = ground_level
			
			# Create context for this collision
			var incoming_state = IncomingMotionState.new(current_velocity)
			surface_data.collision_point = current_position # Update collision point
			# Create a mock player node for testing
			var mock_player = Node.new()
			mock_player.max_height_y = current_position.y
			mock_player.floor_position_y = ground_level
			mock_player.initial_bounce_position_y = ground_level
			
			var context = CollisionContext.new(
				mock_player,
				incoming_state,
				surface_data,
				player_profile,
				gravity,
				false # Debug off for loop
			)
			
			# Get bounce outcome
			var modifiers = bounce_system.get_collision_modifiers(context)
			
			if modifiers.is_empty():
				printerr("      ERROR: Bounce system returned no modifier on collision!")
				success = false
				break # Exit loop on error
				
			var new_velocity: Vector2 = modifiers[0].vector
			
			# Check for termination (sliding/stopped) based on outcome velocity
			if abs(new_velocity.y) < 0.1: # Check if vertical velocity is killed (sliding/stopped)
				if new_velocity.length() < MIN_STOP_SPEED:
					print("      Step %d: Termination -> STOPPED. Final Vel: %s" % [step_count, str(new_velocity.round())])
					current_velocity = Vector2.ZERO
					success = assert_vector2_approx_eq(new_velocity, Vector2.ZERO, 0.01, "Should be zero velocity when stopped.") and success
					break # Exit loop, test finished
				else:
					print("      Step %d: Termination -> SLIDING. Final Vel: %s" % [step_count, str(new_velocity.round())])
					current_velocity = new_velocity
					# Could add sliding friction simulation here if needed
					# For now, just check that Y is zero and break
					success = assert_true(abs(new_velocity.y) < 0.1, "Sliding velocity Y component should be near zero.") and success
					break # Exit loop, test finished (reached sliding)
			else:
				# Still bouncing
				print("      Step %d: Bounce! New Vel: %s" % [step_count, str(new_velocity.round())])
				current_velocity = new_velocity
		
		# Safety break if somehow velocity explodes upwards
		if current_position.y < -10000:
			printerr("      ERROR: Position Y exploded upwards.")
			success = false
			break

	if step_count >= max_steps:
		printerr("      ERROR: Simulation reached max steps without terminating.")
		success = false

	# Assert: Check that the loop terminated correctly (either stopped or sliding)
	success = assert_true(step_count < max_steps, "Simulation should terminate before max steps.") and success
	success = assert_true(abs(current_velocity.y) < 0.1, "Final state should have near-zero Y velocity (Sliding/Stopped).") and success

	return success
