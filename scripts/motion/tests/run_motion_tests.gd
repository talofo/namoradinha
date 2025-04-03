#!/usr/bin/env -S godot --headless --script
extends SceneTree

# This script runs the MotionSystem tests in headless mode
# Usage: godot --headless --script scripts/motion/tests/run_motion_tests.gd

func _init():
	print("Starting MotionSystem tests...")
	
	# Create and run the tests
	var test_runner = load("res://scripts/motion/tests/test_motion_system.gd").new()
	var tests_passed = test_runner.run_tests()
	
	# Exit with appropriate status code
	quit(0 if tests_passed else 1)
