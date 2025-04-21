#!/usr/bin/env -S godot --headless --script
# scripts/environment/tests/run_environment_tests.gd
# Test runner script for the Environment System tests.
extends SceneTree

# Test files to run
const TEST_FILES = [
	"res://scripts/environment/tests/test_environment_system.gd",
	"res://scripts/environment/tests/test_ground_visual_manager.gd",
	"res://scripts/environment/tests/test_effects_manager.gd",
	"res://scripts/environment/tests/test_environment_integration.gd"
]

func _init():
	print("\n=== Environment System Test Suite ===\n")
	
	var all_passed = true
	var test_count = 0
	
	# Run each test file
	for test_file in TEST_FILES:
		print("Running tests from: " + test_file)
		
		# Load and instantiate the test script
		var script = load(test_file)
		if not script:
			print("  ERROR: Could not load test file: " + test_file)
			all_passed = false
			continue
		
		var test_instance = script.new()
		get_root().add_child(test_instance)
		
		# Wait for tests to complete
		await get_frame()
		await get_frame()
		
		# Clean up
		test_instance.queue_free()
		test_count += 1
		
		print("Completed tests from: " + test_file + "\n")
	
	# Print summary
	print("\n=== Test Summary ===")
	print("Ran " + str(test_count) + " test files")
	if all_passed:
		print("All tests completed successfully!")
	else:
		print("Some tests failed. Check the output above for details.")
	print("===================\n")
	
	# Exit with appropriate status code
	quit(0 if all_passed else 1)
