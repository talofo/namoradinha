# scripts/environment/tests/test_environment_integration.gd
# Integration test script for the Environment System.
extends Node

# Mock GlobalSignals for testing
class MockGlobalSignals:
	signal stage_loaded(config)
	signal theme_changed(theme_id)
	signal biome_changed(biome_id)

# Create a mock GlobalSignals instance for testing
var GlobalSignals = MockGlobalSignals.new()

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

# --- Test Subjects ---
var environment_system = null
var stage_manager = null
var theme_database = null

# --- Signal Tracking ---
var visuals_updated_received = false
var transition_completed_received = false
var fallback_activated_received = false
var received_theme_id = ""
var received_biome_id = ""

# --- Test Suite ---
func _ready():
	print("\n--- Testing Environment System Integration ---")
	
	# Setup
	_setup_test_environment()
	
	var all_passed = true

	# --- Individual Tests ---
	print("Running test: test_stage_loading_integration")
	if not await test_stage_loading_integration(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_theme_switching_integration")
	if not await test_theme_switching_integration(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_biome_changing_integration")
	if not await test_biome_changing_integration(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	# Ground data integration test is no longer needed as GroundManager has been removed
	print("Skipping test: test_ground_data_integration (GroundManager has been removed)")

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
	# Create theme database and themes
	var ThemeDatabaseClass = load("res://resources/environment/ThemeDatabase.gd")
	var EnvironmentThemeClass = load("res://resources/environment/EnvironmentTheme.gd")
	
	theme_database = ThemeDatabaseClass.new()
	
	var default_theme = EnvironmentThemeClass.new()
	default_theme.theme_id = "default"
	default_theme.ground_tint = Color(1, 1, 1)
	
	var debug_theme = EnvironmentThemeClass.new()
	debug_theme.theme_id = "debug"
	debug_theme.ground_tint = Color(1, 0, 1, 1)  # Magenta
	
	var forest_theme = EnvironmentThemeClass.new()
	forest_theme.theme_id = "forest"
	forest_theme.ground_tint = Color(0.2, 0.8, 0.2)  # Green
	forest_theme.enable_effects = true
	forest_theme.effect_type = "fog"
	
	theme_database.themes = {
		"default": default_theme,
		"debug": debug_theme,
		"forest": forest_theme
	}
	
	# Create environment system from scene
	var environment_system_scene = load("res://environment/EnvironmentSystem.tscn")
	if not environment_system_scene:
		printerr("    FATAL: Failed to load EnvironmentSystem.tscn")
		return # Cannot proceed
		
	environment_system = environment_system_scene.instantiate()
	if not environment_system:
		printerr("    FATAL: Failed to instantiate EnvironmentSystem.tscn")
		return # Cannot proceed
		
	# Assign the test theme database
	environment_system.theme_database = theme_database
	
	# Create stage manager
	var StageManagerClass = load("res://scripts/stages/StageManager.gd")
	stage_manager = StageManagerClass.new()
	
	# We no longer need to create a GroundManager as it's been replaced by the chunk system
	
	# Connect signals for testing
	environment_system.visuals_updated.connect(_on_visuals_updated)
	environment_system.transition_completed.connect(_on_transition_completed)
	environment_system.fallback_activated.connect(_on_fallback_activated)
	
	add_child(environment_system)
	add_child(stage_manager)

func _cleanup_test_environment():
	# Disconnect signals
	if environment_system:
		if environment_system.visuals_updated.is_connected(_on_visuals_updated):
			environment_system.visuals_updated.disconnect(_on_visuals_updated)
		if environment_system.transition_completed.is_connected(_on_transition_completed):
			environment_system.transition_completed.disconnect(_on_transition_completed)
		if environment_system.fallback_activated.is_connected(_on_fallback_activated):
			environment_system.fallback_activated.disconnect(_on_fallback_activated)
	
	# Free resources
	if environment_system:
		environment_system.queue_free()
	if stage_manager:
		stage_manager.queue_free()
	
	environment_system = null
	stage_manager = null
	theme_database = null

# --- Signal Handlers ---

func _on_visuals_updated(theme_id: String, biome_id: String):
	visuals_updated_received = true
	received_theme_id = theme_id
	received_biome_id = biome_id

func _on_transition_completed():
	transition_completed_received = true

func _on_fallback_activated(manager_name: String, reason: String):
	fallback_activated_received = true

# --- Reset Signal Tracking ---

func _reset_signal_tracking():
	visuals_updated_received = false
	transition_completed_received = false
	fallback_activated_received = false
	received_theme_id = ""
	received_biome_id = ""

# --- Test Cases ---

# Test stage loading integration
func test_stage_loading_integration() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Create stage config
	var StageConfigClass = load("res://resources/environment/StageConfig.gd")
	var config = StageConfigClass.new()
	config.stage_id = 1
	config.theme_id = "forest"
	config.biome_id = "forest"
	
	# Emit stage_loaded signal on the real GlobalSignals singleton
	# In Godot, autoloaded singletons are accessed by their name
	var global_signals = get_node("/root/GlobalSignals")
	global_signals.stage_loaded.emit(config)
	
	# Allow the system to process the signal
	await get_tree().process_frame
	
	# Check that visuals_updated signal was emitted
	success = assert_true(visuals_updated_received, "visuals_updated signal should be emitted") and success
	success = assert_eq(received_theme_id, "forest", "Theme ID should be forest") and success
	success = assert_eq(received_biome_id, "forest", "Biome ID should be forest") and success
	
	# Check that environment system state was updated
	success = assert_eq(environment_system.current_theme_id, "forest", "Current theme should be forest") and success
	success = assert_eq(environment_system.current_biome_id, "forest", "Current biome should be forest") and success
	success = assert_eq(environment_system.current_config, config, "Current config should be set") and success
	
	return success

# Test theme switching integration
func test_theme_switching_integration() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Emit theme_changed signal on the real GlobalSignals singleton
	var global_signals = get_node("/root/GlobalSignals")
	global_signals.theme_changed.emit("debug")
	
	# Allow the system to process the signal
	await get_tree().process_frame
	
	# Check that visuals_updated signal was emitted
	success = assert_true(visuals_updated_received, "visuals_updated signal should be emitted") and success
	success = assert_eq(received_theme_id, "debug", "Theme ID should be debug") and success
	
	# Check that environment system state was updated
	success = assert_eq(environment_system.current_theme_id, "debug", "Current theme should be debug") and success
	
	return success

# Test biome changing integration
func test_biome_changing_integration() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Emit biome_changed signal on the real GlobalSignals singleton
	var global_signals = get_node("/root/GlobalSignals")
	global_signals.biome_changed.emit("desert")
	
	# Allow the system to process the signal
	await get_tree().process_frame
	
	# Check that visuals_updated signal was emitted
	success = assert_true(visuals_updated_received, "visuals_updated signal should be emitted") and success
	success = assert_eq(received_biome_id, "desert", "Biome ID should be desert") and success
	
	# Check that environment system state was updated
	success = assert_eq(environment_system.current_biome_id, "desert", "Current biome should be desert") and success
	
	return success
