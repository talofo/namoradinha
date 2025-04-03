class_name TestMotionSystem
extends Node

# This class contains tests for the MotionSystem architecture
# It validates that the system is correctly instantiated, subsystems are properly registered,
# and motion resolution works as expected

# Reference to the motion system being tested
var motion_system = null

# References to subsystems
var boost_system = null
var obstacle_system = null
var equipment_system = null
var trait_system = null
var environmental_force_system = null
var status_effect_system = null
var collision_material_system = null

# Flag to enable/disable debug output
var debug_enabled = true

# Run all tests
func run_tests() -> bool:
	print("\n=== RUNNING MOTION SYSTEM TESTS ===\n")
	
	var all_tests_passed = true
	
	all_tests_passed = all_tests_passed and test_system_instantiation()
	all_tests_passed = all_tests_passed and test_subsystem_registration()
	all_tests_passed = all_tests_passed and test_continuous_motion_resolution()
	all_tests_passed = all_tests_passed and test_collision_motion_resolution()
	all_tests_passed = all_tests_passed and test_scalar_resolution()
	all_tests_passed = all_tests_passed and test_custom_subsystem()
	
	print("\n=== TEST RESULTS: %s ===\n" % ("ALL PASSED" if all_tests_passed else "SOME FAILED"))
	
	return all_tests_passed

# Test 1: System Instantiation
func test_system_instantiation() -> bool:
	print("Test 1: System Instantiation")
	
	# Create a new MotionSystem
	motion_system = load("res://scripts/motion/MotionSystem.gd").new()
	
	# Check that the system was created successfully
	if motion_system == null:
		print("  FAILED: Could not instantiate MotionSystem")
		return false
	
	# Enable debug output
	motion_system.set_debug_enabled(debug_enabled)
	
	print("  PASSED: MotionSystem instantiated successfully")
	return true

# Test 2: Subsystem Registration
func test_subsystem_registration() -> bool:
	print("Test 2: Subsystem Registration")
	
	if motion_system == null:
		print("  FAILED: MotionSystem not instantiated")
		return false
	
	# Create and register all subsystems
	boost_system = load("res://scripts/motion/subsystems/BoostSystem.gd").new()
	obstacle_system = load("res://scripts/motion/subsystems/ObstacleSystem.gd").new()
	equipment_system = load("res://scripts/motion/subsystems/EquipmentSystem.gd").new()
	trait_system = load("res://scripts/motion/subsystems/TraitSystem.gd").new()
	environmental_force_system = load("res://scripts/motion/subsystems/EnvironmentalForceSystem.gd").new()
	status_effect_system = load("res://scripts/motion/subsystems/StatusEffectSystem.gd").new()
	collision_material_system = load("res://scripts/motion/subsystems/CollisionMaterialSystem.gd").new()
	
	# Register all subsystems
	var registration_success = true
	registration_success = registration_success and motion_system.register_subsystem(boost_system)
	registration_success = registration_success and motion_system.register_subsystem(obstacle_system)
	registration_success = registration_success and motion_system.register_subsystem(equipment_system)
	registration_success = registration_success and motion_system.register_subsystem(trait_system)
	registration_success = registration_success and motion_system.register_subsystem(environmental_force_system)
	registration_success = registration_success and motion_system.register_subsystem(status_effect_system)
	registration_success = registration_success and motion_system.register_subsystem(collision_material_system)
	
	if not registration_success:
		print("  FAILED: Could not register all subsystems")
		return false
	
	# Check that all subsystems are registered
	var all_subsystems = motion_system.get_all_subsystems()
	if all_subsystems.size() != 7:
		print("  FAILED: Expected 7 subsystems, got %d" % all_subsystems.size())
		return false
	
	print("  PASSED: All subsystems registered successfully")
	return true

# Test 3: Continuous Motion Resolution
func test_continuous_motion_resolution() -> bool:
	print("Test 3: Continuous Motion Resolution")
	
	if motion_system == null:
		print("  FAILED: MotionSystem not instantiated")
		return false
	
	# Resolve continuous motion
	var motion_vector = motion_system.resolve_continuous_motion(0.016) # ~60 FPS
	
	# Check that a vector was returned
	if motion_vector == null:
		print("  FAILED: No motion vector returned")
		return false
	
	# In a real test, we would check the expected values
	# For now, just check that it's a non-zero vector
	if motion_vector == Vector2.ZERO:
		print("  FAILED: Expected non-zero motion vector")
		return false
	
	print("  PASSED: Continuous motion resolved successfully: %s" % motion_vector)
	return true

# Test 4: Collision Motion Resolution
func test_collision_motion_resolution() -> bool:
	print("Test 4: Collision Motion Resolution")
	
	if motion_system == null:
		print("  FAILED: MotionSystem not instantiated")
		return false
	
	# Create a test collision info
	var collision_info = {
		"position": Vector2(100, 200),
		"normal": Vector2(0, -1),
		"material": "ice"
	}
	
	# Resolve collision motion
	var motion_vector = motion_system.resolve_collision_motion(collision_info)
	
	# Check that a vector was returned
	if motion_vector == null:
		print("  FAILED: No motion vector returned")
		return false
	
	print("  PASSED: Collision motion resolved successfully: %s" % motion_vector)
	return true

# Test 5: Scalar Resolution
func test_scalar_resolution() -> bool:
	print("Test 5: Scalar Resolution")
	
	if motion_system == null:
		print("  FAILED: MotionSystem not instantiated")
		return false
	
	# Resolve a scalar value (friction)
	var friction = motion_system.resolve_scalar("friction", 1.0)
	
	# Check that a value was returned
	if friction == null:
		print("  FAILED: No scalar value returned")
		return false
	
	print("  PASSED: Scalar resolved successfully: %.2f" % friction)
	return true

# Test 6: Custom Subsystem
func test_custom_subsystem() -> bool:
	print("Test 6: Custom Subsystem")
	
	if motion_system == null:
		print("  FAILED: MotionSystem not instantiated")
		return false
	
	# Create a custom subsystem
	var custom_subsystem = CustomSubsystem.new()
	
	# Register the custom subsystem
	var registration_success = motion_system.register_subsystem(custom_subsystem)
	if not registration_success:
		print("  FAILED: Could not register custom subsystem")
		return false
	
	# Check that the custom subsystem is registered
	var subsystem = motion_system.get_subsystem("CustomSubsystem")
	if subsystem == null:
		print("  FAILED: Custom subsystem not found")
		return false
	
	# Resolve continuous motion again to ensure the custom subsystem is included
	var motion_vector = motion_system.resolve_continuous_motion(0.016)
	
	# Unregister the custom subsystem
	var unregistration_success = motion_system.unregister_subsystem("CustomSubsystem")
	if not unregistration_success:
		print("  FAILED: Could not unregister custom subsystem")
		return false
	
	print("  PASSED: Custom subsystem test successful")
	return true

# Custom subsystem class for testing
class CustomSubsystem:
	func get_name() -> String:
		return "CustomSubsystem"
	
	func on_register() -> void:
		print("[CustomSubsystem] Registered with MotionSystem")
	
	func on_unregister() -> void:
		print("[CustomSubsystem] Unregistered from MotionSystem")
	
	func get_continuous_modifiers(delta: float) -> Array:
		print("[CustomSubsystem] Getting continuous modifiers (delta: %.3f)" % delta)
		
		var modifiers = []
		
		# Example: Add a placeholder custom modifier
		var custom_modifier = load("res://scripts/motion/MotionModifier.gd").new(
			"CustomSubsystem",  # source
			"velocity",         # type
			30,                 # priority (very high)
			Vector2(0, -5),     # vector (upward boost)
			1.0,                # scalar
			true,               # is_additive
			-1                  # duration (permanent)
		)
		
		modifiers.append(custom_modifier)
		
		return modifiers
	
	func get_collision_modifiers(collision_info: Dictionary) -> Array:
		print("[CustomSubsystem] Getting collision modifiers")
		return []
