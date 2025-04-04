#!/usr/bin/env -S godot --script
extends SceneTree

func _init():
	print("Running LaunchSystem Test")
	
	# Load and run the test scene
	var test_scene = load("res://scripts/motion/tests/LaunchSystemTest.tscn")
	if test_scene:
		print("Test scene loaded successfully")
		var instance = test_scene.instantiate()
		get_root().add_child(instance)
		print("Test scene added to root")
	else:
		push_error("Failed to load test scene")
		quit(1)
	
	print("LaunchSystem Test running. Press Ctrl+C to exit.")

# Handle quit events
func _process(_delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		print("Escape key pressed, quitting...")
		quit()
