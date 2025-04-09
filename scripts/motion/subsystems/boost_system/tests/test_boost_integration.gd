# scripts/motion/subsystems/boost_system/tests/test_boost_integration.gd
# Integration test for the Boost System, simulating a full sequence of motion with boosts.
extends Node

# --- Test Framework Setup (Basic Assertions) ---
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

func assert_vector2_approx_eq(v1: Vector2, v2: Vector2, tolerance: float = 0.001, message: String = ""):
	# Manual approximate comparison using tolerance
	if (v1 - v2).length_squared() >= tolerance * tolerance:
		printerr("    Assertion Failed: Expected Vector2 %s approx == %s (tolerance: %f). Difference: %s. %s" % [str(v1), str(v2), tolerance, str(v1-v2), message])
		return false
	return true

# --- Test Subject ---
var boost_system = null
var physics_config = null

# --- Test Suite ---
func _ready():
	print("\n--- Testing BoostSystem Integration (In-Scene) ---")
	
	# Setup
	boost_system = load("res://scripts/motion/subsystems/boost_system/BoostSystem.gd").new()
	physics_config = {
		"manual_air_boost_rising_strength": 300.0,
		"manual_air_boost_rising_angle": 45.0,
		"manual_air_boost_falling_strength": 500.0,
		"manual_air_boost_falling_angle": -60.0
	}
	boost_system.set_physics_config(physics_config)
	
	var all_passed = true

	# --- Individual Tests (Direct Calls) ---
	print("Running test: test_full_motion_sequence")
	if not test_full_motion_sequence():
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
	
	# Cleanup
	boost_system = null
	physics_config = null

# --- Test Cases ---

# Test a full sequence of motion with boosts applied at different points.
func test_full_motion_sequence() -> bool:
	var success = true
	
	print("    Simulating sequence: Launch -> Rising Boost -> Falling Boost -> Landing")
	
	# Arrange: Initial launch state
	var current_velocity = Vector2(300, -600) # Initial launch velocity (right and up)
	var current_position = Vector2(0, 0)      # Start position
	var gravity_value = 1000.0                # Gravity strength
	var gravity = Vector2(0, gravity_value)   # Gravity vector (down)
	var delta_time = 0.05                     # Simulation time step
	var max_steps = 100                       # Prevent infinite loops
	var step_count = 0
	var ground_level = 500.0                  # Ground Y position
	
	# Boost application flags
	var rising_boost_applied = false
	var falling_boost_applied = false
	
	print("      Initial Velocity: ", current_velocity)
	
	# Act: Simulate physics steps with boosts
	while step_count < max_steps:
		step_count += 1
		
		# 1. Apply gravity and update position
		current_velocity += gravity * delta_time
		current_position += current_velocity * delta_time
		
		# 2. Determine if we're rising or falling
		var is_rising = current_velocity.y < 0 # In Godot, negative Y is up
		
		# 3. Apply boosts at specific points in the trajectory
		if is_rising and not rising_boost_applied and step_count > 5:
			# Apply a rising boost after a few steps
			var state_data = {
				"is_airborne": true,
				"is_rising": true,
				"velocity": current_velocity,
				"position": current_position
			}
			
			var result = boost_system.try_apply_boost(1, "manual_air", state_data)
			
			if result["success"]:
				rising_boost_applied = true
				var boost_vector = result["boost_vector"]
				current_velocity = result["resulting_velocity"]
				print("      Step %d: Rising Boost Applied! Pos: %s, New Vel: %s, Boost Vector: %s" % 
					[step_count, str(current_position.round()), str(current_velocity.round()), str(boost_vector.round())])
				
				# Verify the boost has expected properties
				success = assert_true(boost_vector.y < 0, "Rising boost should have upward component (negative Y).") and success
				success = assert_true(boost_vector.x > 0, "Rising boost should have rightward component (positive X).") and success
			else:
				print("      Step %d: Rising Boost Failed! Reason: %s" % [step_count, result["reason"]])
				success = false
				break
		
		elif not is_rising and not falling_boost_applied and step_count > 15:
			# Apply a falling boost after we start falling
			var state_data = {
				"is_airborne": true,
				"is_rising": false,
				"velocity": current_velocity,
				"position": current_position
			}
			
			var result = boost_system.try_apply_boost(1, "manual_air", state_data)
			
			if result["success"]:
				falling_boost_applied = true
				var boost_vector = result["boost_vector"]
				current_velocity = result["resulting_velocity"]
				print("      Step %d: Falling Boost Applied! Pos: %s, New Vel: %s, Boost Vector: %s" % 
					[step_count, str(current_position.round()), str(current_velocity.round()), str(boost_vector.round())])
				
				# Verify the boost has expected properties
				success = assert_true(boost_vector.y > 0, "Falling boost should have downward component (positive Y).") and success
				success = assert_true(boost_vector.x > 0, "Falling boost should have rightward component (positive X).") and success
			else:
				print("      Step %d: Falling Boost Failed! Reason: %s" % [step_count, result["reason"]])
				success = false
				break
		
		# 4. Check for ground collision
		if current_position.y >= ground_level:
			print("      Step %d: Landing! Final Position: %s, Final Velocity: %s" % 
				[step_count, str(current_position.round()), str(current_velocity.round())])
			break
		
		# Print state every 10 steps for debugging
		if step_count % 10 == 0:
			print("      Step %d: Pos: %s, Vel: %s, Rising: %s" % 
				[step_count, str(current_position.round()), str(current_velocity.round()), str(is_rising)])
	
	# Assert: Check that both boosts were applied and we landed
	success = assert_true(rising_boost_applied, "Rising boost should have been applied.") and success
	success = assert_true(falling_boost_applied, "Falling boost should have been applied.") and success
	success = assert_true(current_position.y >= ground_level, "Simulation should end with landing.") and success
	success = assert_true(step_count < max_steps, "Simulation should not reach max steps.") and success
	
	return success
