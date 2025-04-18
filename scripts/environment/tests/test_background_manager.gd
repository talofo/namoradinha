# scripts/environment/tests/test_background_manager.gd
# Test script for the BackgroundManager component.
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
var background_manager = null
var test_theme = null

# --- Signal Tracking ---
var transition_completed_received = false
var fallback_activated_received = false
var fallback_reason = ""

# --- Test Suite ---
func _ready():
	print("\n--- Testing BackgroundManager ---")
	
	# Setup
	_setup_test_environment()
	
	var all_passed = true

	# --- Individual Tests ---
	print("Running test: test_apply_theme_single_background")
	if not await test_apply_theme_single_background(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_apply_theme_multiple_backgrounds")
	if not await test_apply_theme_multiple_backgrounds(): # Added await
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
		
	print("Running test: test_parallax_settings")
	if not await test_parallax_settings(): # Added await
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
	test_theme.background_tint = Color(0.8, 0.8, 0.8)
	test_theme.parallax_ratio = Vector2(0.5, 0.5)
	
	# Create background manager from scene
	var background_manager_scene = load("res://environment/managers/BackgroundManager.tscn")
	if not background_manager_scene:
		printerr("    FATAL: Failed to load BackgroundManager.tscn")
		return # Cannot proceed
		
	background_manager = background_manager_scene.instantiate()
	if not background_manager:
		printerr("    FATAL: Failed to instantiate BackgroundManager.tscn")
		return # Cannot proceed
		
	# Connect signals for testing
	background_manager.transition_completed.connect(_on_transition_completed)
	background_manager.fallback_activated.connect(_on_fallback_activated)
	
	add_child(background_manager)
	
	# Layers are now part of the scene instance, no need to create manually

func _cleanup_test_environment():
	# Disconnect signals
	if background_manager:
		if background_manager.transition_completed.is_connected(_on_transition_completed):
			background_manager.transition_completed.disconnect(_on_transition_completed)
		if background_manager.fallback_activated.is_connected(_on_fallback_activated):
			background_manager.fallback_activated.disconnect(_on_fallback_activated)
	
	# Free resources
	if background_manager:
		background_manager.queue_free()
	
	background_manager = null
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

# Test applying a theme with a single background
func test_apply_theme_single_background() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Configure theme for single background
	test_theme.use_single_background = true
	test_theme.background_far_texture = ImageTexture.new()
	test_theme.background_mid_texture = null
	test_theme.background_near_texture = null
	
	# Apply theme
	background_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Check that layers were created
	success = assert_not_null(background_manager.far_layer, "Far layer should exist") and success
	success = assert_not_null(background_manager.mid_layer, "Mid layer should exist") and success
	success = assert_not_null(background_manager.near_layer, "Near layer should exist") and success
	
	return success

# Test applying a theme with multiple backgrounds
func test_apply_theme_multiple_backgrounds() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Configure theme for multiple backgrounds
	test_theme.use_single_background = false
	test_theme.background_far_texture = ImageTexture.new()
	test_theme.background_mid_texture = ImageTexture.new()
	test_theme.background_near_texture = ImageTexture.new()
	
	# Apply theme
	background_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Check that layers were created
	success = assert_not_null(background_manager.far_layer, "Far layer should exist") and success
	success = assert_not_null(background_manager.mid_layer, "Mid layer should exist") and success
	success = assert_not_null(background_manager.near_layer, "Near layer should exist") and success
	
	return success

# Test fallback handling
func test_fallback_handling() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Configure theme with missing textures
	test_theme.use_single_background = true
	test_theme.background_far_texture = null
	
	# Apply theme (should trigger fallback)
	background_manager.apply_theme(test_theme)
	
	# Check that fallback_activated signal was emitted
	success = assert_true(fallback_activated_received, "fallback_activated signal should be emitted") and success
	success = assert_true(fallback_reason.length() > 0, "Fallback reason should be provided") and success
	
	# Check that fallback visuals were created
	var has_fallback = false
	if background_manager.far_layer:
		for child in background_manager.far_layer.get_children():
			if child is ColorRect and child.name == "Fallback":
				has_fallback = true
				break
	
	success = assert_true(has_fallback, "Fallback visual should be created") and success
	
	return success

# Test parallax settings
func test_parallax_settings() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Configure theme with specific parallax ratio
	test_theme.use_single_background = true
	test_theme.background_far_texture = ImageTexture.new()
	test_theme.parallax_ratio = Vector2(0.25, 0.25)
	
	# Apply theme
	background_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Check that parallax settings were applied
	if background_manager.far_layer:
		success = assert_eq(background_manager.far_layer.motion_scale, test_theme.parallax_ratio, "Far layer parallax ratio should match theme") and success
	else:
		success = false
		printerr("    Assertion Failed: Far layer does not exist")
	
	if background_manager.mid_layer:
		success = assert_eq(background_manager.mid_layer.motion_scale, test_theme.parallax_ratio * 1.5, "Mid layer parallax ratio should be 1.5x theme value") and success
	else:
		success = false
		printerr("    Assertion Failed: Mid layer does not exist")
	
	if background_manager.near_layer:
		success = assert_eq(background_manager.near_layer.motion_scale, test_theme.parallax_ratio * 2.0, "Near layer parallax ratio should be 2x theme value") and success
	else:
		success = false
		printerr("    Assertion Failed: Near layer does not exist")
	
	return success
