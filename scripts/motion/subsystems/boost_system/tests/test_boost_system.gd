# scripts/motion/subsystems/boost_system/tests/test_boost_system.gd
# Test script for the new BoostSystem and its components.
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

func assert_ne(val1, val2, message: String = ""):
	if val1 == val2:
		printerr("    Assertion Failed: Expected '%s' != '%s'. %s" % [str(val1), str(val2), message])
		return false
	return true

func assert_has(dict: Dictionary, key: String, message: String = ""):
	if not dict.has(key):
		printerr("    Assertion Failed: Dictionary does not have key '%s'. %s" % [key, message])
		return false
	return true

func assert_lt(val1, val2, message: String = ""):
	if not (val1 < val2):
		printerr("    Assertion Failed: Expected '%s' < '%s'. %s" % [str(val1), str(val2), message])
		return false
	return true

func assert_gt(val1, val2, message: String = ""):
	if not (val1 > val2):
		printerr("    Assertion Failed: Expected '%s' > '%s'. %s" % [str(val1), str(val2), message])
		return false
	return true

# --- Test Subject ---
var boost_system = null
var physics_config = null

# --- Test Suite ---
func _ready():
	print("\n--- Testing BoostSystem (In-Scene) ---")
	
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
	print("Running test: test_unknown_boost_type")
	if not test_unknown_boost_type():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_non_airborne_rejection")
	if not test_non_airborne_rejection():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_rising_boost")
	if not test_rising_boost():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_falling_boost")
	if not test_falling_boost():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_boost_signal")
	if not test_boost_signal():
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
	# No need to free boost_system as it extends RefCounted
	boost_system = null
	physics_config = null

# --- Test Cases ---

# Test that attempting to use an unregistered boost type fails correctly.
func test_unknown_boost_type() -> bool:
	var success = true
	
	# Arrange: Prepare state data (doesn't matter much for this test)
	var state_data = {"is_airborne": true, "is_rising": true, "velocity": Vector2.ZERO}
	var entity_id = 1

	# Act: Try to apply a boost type that doesn't exist
	var result = boost_system.try_apply_boost(entity_id, "nonexistent_boost_type", state_data)

	# Assert: Check for failure and the correct reason
	success = assert_false(result["success"], "Boost should fail for an unknown boost type.") and success
	success = assert_eq(result["reason"], "unknown_boost_type", "Failure reason should be 'unknown_boost_type'.") and success
	
	return success

# Test that the ManualAirBoost is correctly rejected when the entity is not airborne.
func test_non_airborne_rejection() -> bool:
	var success = true
	
	# Arrange: State data indicating the entity is not airborne
	var state_data = {"is_airborne": false, "is_rising": false, "velocity": Vector2.ZERO}
	var entity_id = 2

	# Act: Try to apply the manual air boost
	var result = boost_system.try_apply_boost(entity_id, "manual_air", state_data)

	# Assert: Check for failure and the correct reason
	success = assert_false(result["success"], "Manual air boost should fail when not airborne.") and success
	success = assert_eq(result["reason"], "invalid_state_for_boost", "Failure reason should be 'invalid_state_for_boost'.") and success
	
	return success

# Test that the ManualAirBoost applies correctly when the entity is rising.
func test_rising_boost() -> bool:
	var success = true
	
	# Arrange: State data indicating the entity is airborne and rising
	var initial_velocity = Vector2(50, -100) # Example velocity, Y is negative (up)
	var state_data = {
		"is_airborne": true,
		"is_rising": true, # Explicitly rising
		"velocity": initial_velocity
	}
	var entity_id = 3

	# Act: Apply the manual air boost
	var result = boost_system.try_apply_boost(entity_id, "manual_air", state_data)

	# Assert: Check for success and expected vector properties
	success = assert_true(result["success"], "Manual air boost should succeed when rising and airborne.") and success
	success = assert_has(result, "boost_vector", "Result should contain 'boost_vector'.") and success
	success = assert_has(result, "resulting_velocity", "Result should contain 'resulting_velocity'.") and success

	if result.has("boost_vector") and result.has("resulting_velocity"):
		var boost_vector: Vector2 = result["boost_vector"]
		var resulting_velocity: Vector2 = result["resulting_velocity"]

		# Check if boost vector is non-zero (basic check)
		success = assert_false(boost_vector.is_zero_approx(), "Boost vector should not be zero.") and success

		# Check if the boost vector has an upward component (negative Y in Godot 2D)
		# Based on DEFAULT_RISING_BOOST_ANGLE = 45.0
		success = assert_lt(boost_vector.y, 0.0, "Rising boost vector Y component should be negative (upward).") and success
		# Check if the boost vector has a rightward component (positive X)
		success = assert_gt(boost_vector.x, 0.0, "Rising boost vector X component should be positive (rightward).") and success

		# Check resulting velocity
		success = assert_eq(resulting_velocity, initial_velocity + boost_vector, "Resulting velocity should be initial + boost.") and success
	
	return success

# Test that the ManualAirBoost applies correctly when the entity is falling.
func test_falling_boost() -> bool:
	var success = true
	
	# Arrange: State data indicating the entity is airborne and falling
	var initial_velocity = Vector2(50, 100) # Example velocity, Y is positive (down)
	var state_data = {
		"is_airborne": true,
		"is_rising": false, # Explicitly falling
		"velocity": initial_velocity
	}
	var entity_id = 4

	# Act: Apply the manual air boost
	var result = boost_system.try_apply_boost(entity_id, "manual_air", state_data)

	# Assert: Check for success and expected vector properties
	success = assert_true(result["success"], "Manual air boost should succeed when falling and airborne.") and success
	success = assert_has(result, "boost_vector", "Result should contain 'boost_vector'.") and success
	success = assert_has(result, "resulting_velocity", "Result should contain 'resulting_velocity'.") and success

	if result.has("boost_vector") and result.has("resulting_velocity"):
		var boost_vector: Vector2 = result["boost_vector"]
		var resulting_velocity: Vector2 = result["resulting_velocity"]

		# Check if boost vector is non-zero (basic check)
		success = assert_false(boost_vector.is_zero_approx(), "Boost vector should not be zero.") and success

		# Check if the boost vector has a downward component (positive Y in Godot 2D)
		# Based on DEFAULT_FALLING_BOOST_ANGLE = -60.0
		success = assert_gt(boost_vector.y, 0.0, "Falling boost vector Y component should be positive (downward).") and success
		# Check if the boost vector has a rightward component (positive X)
		success = assert_gt(boost_vector.x, 0.0, "Falling boost vector X component should be positive (rightward).") and success

		# Check resulting velocity
		success = assert_eq(resulting_velocity, initial_velocity + boost_vector, "Resulting velocity should be initial + boost.") and success
	
	return success

# Variables for signal testing
var signal_received = false
var received_entity_id = -1
var received_boost_vector = Vector2.ZERO
var received_boost_type = ""

# Signal handler for boost_applied signal
func _on_boost_applied(eid, bv, bt):
	signal_received = true
	received_entity_id = eid
	received_boost_vector = bv
	received_boost_type = bt

# Test that the boost_applied signal is emitted correctly.
func test_boost_signal() -> bool:
	var success = true
	
	# Reset signal variables
	signal_received = false
	received_entity_id = -1
	received_boost_vector = Vector2.ZERO
	received_boost_type = ""
	
	# Arrange: State data for a valid boost
	var state_data = {
		"is_airborne": true,
		"is_rising": true,
		"velocity": Vector2(50, -100)
	}
	var entity_id = 5
	
	# Connect to the signal
	# In Godot 4, we need to use the Callable syntax for connecting signals
	var callable = Callable(self, "_on_boost_applied")
	if boost_system.is_connected("boost_applied", callable):
		boost_system.disconnect("boost_applied", callable)
	boost_system.connect("boost_applied", callable)
	
	# Act: Apply a boost that should succeed
	var result = boost_system.try_apply_boost(entity_id, "manual_air", state_data)
	
	# Assert: Check signal was emitted with correct parameters
	success = assert_true(signal_received, "boost_applied signal should be emitted.") and success
	success = assert_eq(received_entity_id, entity_id, "Signal should pass the correct entity_id.") and success
	success = assert_eq(received_boost_type, "manual_air", "Signal should pass the correct boost_type.") and success
	
	# The boost vector should match what's in the result
	if result.has("boost_vector"):
		success = assert_eq(received_boost_vector, result["boost_vector"], "Signal boost_vector should match result boost_vector.") and success
	
	return success
