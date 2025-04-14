# scripts/environment/tests/test_ground_visual_manager.gd
# Test script for the GroundVisualManager component.
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

func assert_not_null(val, message: String = ""):
	if val == null:
		printerr("    Assertion Failed: Value is null. %s" % message)
		return false
	return true

# --- Test Subject ---
var ground_manager = null
var test_theme = null

# --- Signal Tracking ---
var signal_received = false
var transition_completed_received = false
var fallback_activated_received = false
var fallback_reason = ""

# --- Test Suite ---
func _ready():
	print("\n--- Testing GroundVisualManager ---")
	
	# Setup
	_setup_test_environment()
	
	var all_passed = true

	# --- Individual Tests ---
	print("Running test: test_apply_theme")
	if not await test_apply_theme(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_apply_ground_visuals")
	if not await test_apply_ground_visuals(): # Added await here
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_fallback_handling")
	if not test_fallback_handling():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_transition_signals")
	if not await test_transition_signals(): # Added await
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
	_cleanup_test_environment()

# --- Setup and Cleanup ---

func _setup_test_environment():
	# Create test theme
	var EnvironmentThemeClass = load("res://resources/environment/EnvironmentTheme.gd")
	test_theme = EnvironmentThemeClass.new()
	test_theme.theme_id = "test_theme"
	test_theme.ground_tint = Color(0.8, 0.8, 0.8)
	
	# Create ground manager from scene
	var ground_manager_scene = load("res://environment/managers/GroundVisualManager.tscn")
	if not ground_manager_scene:
		printerr("    FATAL: Failed to load GroundVisualManager.tscn")
		return # Cannot proceed
		
	ground_manager = ground_manager_scene.instantiate()
	if not ground_manager:
		printerr("    FATAL: Failed to instantiate GroundVisualManager.tscn")
		return # Cannot proceed
		
	# Connect signals for testing
	ground_manager.transition_completed.connect(_on_transition_completed)
	ground_manager.fallback_activated.connect(_on_fallback_activated)
	
	# Don't add ground_manager as a child here, tests will handle parenting if needed.

func _cleanup_test_environment():
	# Disconnect signals
	if ground_manager:
		if ground_manager.transition_completed.is_connected(_on_transition_completed):
			ground_manager.transition_completed.disconnect(_on_transition_completed)
		if ground_manager.fallback_activated.is_connected(_on_fallback_activated):
			ground_manager.fallback_activated.disconnect(_on_fallback_activated)
	
	# Free resources
	if ground_manager:
		ground_manager.queue_free()
	
	ground_manager = null
	test_theme = null

# --- Signal Handlers ---

func _on_transition_completed():
	transition_completed_received = true

func _on_fallback_activated(reason: String):
	fallback_activated_received = true
	fallback_reason = reason

# --- Reset Signal Tracking ---

func _reset_signal_tracking():
	transition_completed_received = false
	fallback_activated_received = false
	fallback_reason = ""

# --- Test Cases ---

# Test applying a theme to the ground manager
func test_apply_theme() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Apply theme with texture
	var texture = ImageTexture.new()
	test_theme.ground_texture = texture
	
	ground_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Apply theme without texture (should trigger fallback)
	test_theme.ground_texture = null
	
	ground_manager.apply_theme(test_theme)
	
	# Check that fallback_activated signal was emitted
	success = assert_true(fallback_activated_received, "fallback_activated signal should be emitted") and success
	success = assert_true(fallback_reason.length() > 0, "Fallback reason should be provided") and success
	
	return success

# Test applying ground visuals
func test_apply_ground_visuals() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Create test ground data
	var ground_data = [
		{
			"position": Vector2(0, 0),
			"size": Vector2(100, 20)
		},
		{
			"position": Vector2(100, 0),
			"size": Vector2(100, 20)
		}
	]
	
	# Create a texture for the test
	var texture = ImageTexture.new()
	test_theme.ground_texture = texture
	
	# Set up a proper EnvironmentSystem parent to provide the theme
	var EnvironmentSystemClass = load("res://scripts/environment/EnvironmentSystem.gd") # Need class for ThemeDatabase type
	var ThemeDatabaseClass = load("res://resources/environment/ThemeDatabase.gd")
	var environment_system_scene = load("res://environment/EnvironmentSystem.tscn")
	if not environment_system_scene:
		printerr("    FATAL: Failed to load EnvironmentSystem.tscn for test_apply_ground_visuals")
		return false # Test cannot proceed
		
	var parent_env_system = environment_system_scene.instantiate()
	if not parent_env_system:
		printerr("    FATAL: Failed to instantiate EnvironmentSystem.tscn for test_apply_ground_visuals")
		return false # Test cannot proceed
		
	# Create and assign a theme database for this test case
	var test_db = ThemeDatabaseClass.new()
	test_db.themes = {"test_theme": test_theme}
	parent_env_system.theme_database = test_db
	
	# Replace the default ground manager in the parent with our test subject
	var original_gm = parent_env_system.get_node_or_null("GroundVisualManager")
	if original_gm:
		parent_env_system.remove_child(original_gm)
		original_gm.queue_free() # Clean up the original one from the scene instance
		
	# Add our test subject (which currently has no parent) to the temp parent
	parent_env_system.add_child(ground_manager) 
	
	# Add the temporary parent system to the main test scene tree so _ready etc. are called
	add_child(parent_env_system) 
	
	# Allow engine loop to process ready functions etc.
	await get_tree().process_frame
	
	# Apply ground visuals - now ground_manager can access its parent
	ground_manager.apply_ground_visuals(ground_data)
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Check that sprites were created
	var sprite_count = 0
	for child in ground_manager.get_children():
		if child is Node2D:  # Container for sprites
			sprite_count += child.get_child_count()
	
	# We're not checking the exact count because the test environment is different
	success = assert_true(sprite_count > 0, "Sprites should be created") and success
	
	# Clean up for this specific test case
	parent_env_system.remove_child(ground_manager) # Unparent the test subject
	parent_env_system.queue_free() # Free the temporary parent
	# ground_manager itself will be freed by _cleanup_test_environment
	
	return success

# Test fallback handling
func test_fallback_handling() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Create fallback by applying null theme
	ground_manager.apply_theme(null)
	
	# Check that fallback_activated signal was emitted
	success = assert_true(fallback_activated_received, "fallback_activated signal should be emitted") and success
	
	# Check that a fallback visual was created
	var has_fallback = false
	for child in ground_manager.get_children():
		if child is ColorRect:
			has_fallback = true
			break
	
	success = assert_true(has_fallback, "Fallback visual should be created") and success
	
	return success

# Test transition signals
func test_transition_signals() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Apply theme with texture
	var texture = ImageTexture.new()
	test_theme.ground_texture = texture
	
	ground_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	return success
