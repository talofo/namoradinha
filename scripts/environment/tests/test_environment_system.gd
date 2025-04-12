# scripts/environment/tests/test_environment_system.gd
# Test script for the EnvironmentSystem and its components.
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

func assert_not_null(val, message: String = ""):
	if val == null:
		printerr("    Assertion Failed: Value is null. %s" % message)
		return false
	return true

# --- Test Subject ---
var environment_system = null
var theme_database = null
var default_theme = null
var debug_theme = null

# --- Signal Tracking ---
var signal_received = false
var received_theme_id = ""
var received_biome_id = ""
var received_manager_name = ""
var received_reason = ""

# --- Test Suite ---
func _ready():
	print("\n--- Testing EnvironmentSystem ---")
	
	# Setup
	_setup_test_environment()
	
	var all_passed = true

	# --- Individual Tests ---
	print("Running test: test_theme_loading")
	if not test_theme_loading():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_theme_switching")
	if not test_theme_switching():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_biome_changing")
	if not test_biome_changing():
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_stage_config_application")
	if not test_stage_config_application():
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
		
	print("Running test: test_visuals_updated_signal")
	if not test_visuals_updated_signal():
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
	# Create theme database and themes
	var ThemeDatabaseClass = load("res://resources/environment/ThemeDatabase.gd")
	var EnvironmentThemeClass = load("res://resources/environment/EnvironmentTheme.gd")
	
	theme_database = ThemeDatabaseClass.new()
	default_theme = EnvironmentThemeClass.new()
	default_theme.theme_id = "default"
	debug_theme = EnvironmentThemeClass.new()
	debug_theme.theme_id = "debug"
	debug_theme.ground_tint = Color(1, 0, 1, 1)  # Magenta
	
	theme_database.themes = {
		"default": default_theme,
		"debug": debug_theme
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
		
	# Assign the test theme database AFTER instantiating
	# The scene might load its own default, we override it here for testing
	environment_system.theme_database = theme_database
	
	# Managers are now part of the instantiated scene, no need to create mocks
	
	# Connect signals for testing
	environment_system.visuals_updated.connect(_on_visuals_updated)
	environment_system.fallback_activated.connect(_on_fallback_activated)
	
	add_child(environment_system)

func _cleanup_test_environment():
	# Disconnect signals
	if environment_system:
		if environment_system.visuals_updated.is_connected(_on_visuals_updated):
			environment_system.visuals_updated.disconnect(_on_visuals_updated)
		if environment_system.fallback_activated.is_connected(_on_fallback_activated):
			environment_system.fallback_activated.disconnect(_on_fallback_activated)
	
	# Free resources
	if environment_system:
		environment_system.queue_free()
	
	environment_system = null
	theme_database = null
	default_theme = null
	debug_theme = null

# --- Signal Handlers ---

func _on_visuals_updated(theme_id: String, biome_id: String):
	signal_received = true
	received_theme_id = theme_id
	received_biome_id = biome_id

func _on_fallback_activated(manager_name: String, reason: String):
	signal_received = true
	received_manager_name = manager_name
	received_reason = reason

# --- Reset Signal Tracking ---

func _reset_signal_tracking():
	signal_received = false
	received_theme_id = ""
	received_biome_id = ""
	received_manager_name = ""
	received_reason = ""

# --- Test Cases ---

# Test that themes can be loaded from the theme database
func test_theme_loading() -> bool:
	var success = true
	
	# Test getting default theme
	var theme = environment_system.get_theme_by_id("default")
	success = assert_not_null(theme, "Default theme should be loaded") and success
	if theme:
		success = assert_eq(theme.theme_id, "default", "Theme ID should match") and success
	
	# Test getting debug theme
	theme = environment_system.get_theme_by_id("debug")
	success = assert_not_null(theme, "Debug theme should be loaded") and success
	if theme:
		success = assert_eq(theme.theme_id, "debug", "Theme ID should match") and success
		success = assert_eq(theme.ground_tint, Color(1, 0, 1, 1), "Debug theme should have magenta ground tint") and success
	
	# Test getting non-existent theme (should return debug theme as fallback)
	theme = environment_system.get_theme_by_id("nonexistent")
	success = assert_not_null(theme, "Non-existent theme should return debug theme as fallback") and success
	if theme:
		success = assert_eq(theme.theme_id, "debug", "Fallback theme should be debug theme") and success
	
	return success

# Test that themes can be switched
func test_theme_switching() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Apply default theme
	environment_system.apply_theme_by_id("default")
	
	# Check current theme
	success = assert_eq(environment_system.current_theme_id, "default", "Current theme should be default") and success
	
	# Check signal was emitted
	success = assert_true(signal_received, "visuals_updated signal should be emitted") and success
	success = assert_eq(received_theme_id, "default", "Signal should pass correct theme_id") and success
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Apply debug theme
	environment_system.apply_theme_by_id("debug")
	
	# Check current theme
	success = assert_eq(environment_system.current_theme_id, "debug", "Current theme should be debug") and success
	
	# Check signal was emitted
	success = assert_true(signal_received, "visuals_updated signal should be emitted") and success
	success = assert_eq(received_theme_id, "debug", "Signal should pass correct theme_id") and success
	
	return success

# Test that biomes can be changed
func test_biome_changing() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Change biome
	environment_system.change_biome("forest")
	
	# Check current biome
	success = assert_eq(environment_system.current_biome_id, "forest", "Current biome should be forest") and success
	
	# Check signal was emitted
	success = assert_true(signal_received, "visuals_updated signal should be emitted") and success
	success = assert_eq(received_biome_id, "forest", "Signal should pass correct biome_id") and success
	
	return success

# Test that stage configs can be applied
func test_stage_config_application() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Create stage config
	var StageConfigClass = load("res://resources/environment/StageConfig.gd")
	var config = StageConfigClass.new()
	config.stage_id = 2
	config.theme_id = "debug"
	config.biome_id = "desert"
	
	# Apply stage config
	environment_system.apply_stage_config(config)
	
	# Check current state
	success = assert_eq(environment_system.current_theme_id, "debug", "Current theme should be debug") and success
	success = assert_eq(environment_system.current_biome_id, "desert", "Current biome should be desert") and success
	success = assert_eq(environment_system.current_config, config, "Current config should be set") and success
	
	# Check signal was emitted
	success = assert_true(signal_received, "visuals_updated signal should be emitted") and success
	success = assert_eq(received_theme_id, "debug", "Signal should pass correct theme_id") and success
	success = assert_eq(received_biome_id, "desert", "Signal should pass correct biome_id") and success
	
	return success

# Test fallback handling
func test_fallback_handling() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Simulate a fallback from ground manager
	var ground_manager = environment_system.get_node("GroundVisualManager")
	if ground_manager:
		environment_system._on_manager_fallback("GroundVisualManager: Missing texture")
	
	# Check signal was emitted
	success = assert_true(signal_received, "fallback_activated signal should be emitted") and success
	success = assert_eq(received_manager_name, "ground", "Signal should pass correct manager_name") and success
	
	return success

# Test visuals_updated signal
func test_visuals_updated_signal() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Apply theme to trigger signal
	environment_system.apply_theme_by_id("default")
	
	# Check signal was emitted
	success = assert_true(signal_received, "visuals_updated signal should be emitted") and success
	success = assert_eq(received_theme_id, "default", "Signal should pass correct theme_id") and success
	success = assert_eq(received_biome_id, environment_system.current_biome_id, "Signal should pass correct biome_id") and success
	
	return success
