# scripts/environment/tests/test_effects_manager.gd
# Test script for the EffectsManager component.
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
var effects_manager = null
var test_theme = null

# --- Signal Tracking ---
var transition_completed_received = false
var fallback_activated_received = false
var fallback_reason = ""

# --- Test Suite ---
func _ready():
	print("\n--- Testing EffectsManager ---")
	
	# Setup
	_setup_test_environment()
	
	var all_passed = true

	# --- Individual Tests ---
	print("Running test: test_fog_effect")
	if not await test_fog_effect(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_particle_effect")
	if not await test_particle_effect(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_overlay_effect")
	if not await test_overlay_effect(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_disabled_effects")
	if not await test_disabled_effects(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_unknown_effect_type")
	if not await test_unknown_effect_type(): # Added await
		all_passed = false
		print("  [FAIL]")
	else:
		print("  [PASS]")
		
	print("Running test: test_transition_out_effects")
	if not await test_transition_out_effects(): # Added await
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
	test_theme.enable_effects = true
	
	# Create effects manager from scene
	var effects_manager_scene = load("res://environment/managers/EffectsManager.tscn")
	if not effects_manager_scene:
		printerr("    FATAL: Failed to load EffectsManager.tscn")
		return # Cannot proceed
		
	effects_manager = effects_manager_scene.instantiate()
	if not effects_manager:
		printerr("    FATAL: Failed to instantiate EffectsManager.tscn")
		return # Cannot proceed
		
	# Set shorter transition duration for tests
	effects_manager.transition_duration = 0.01  # Very short for tests
	
	# Connect signals for testing
	effects_manager.transition_completed.connect(_on_transition_completed)
	effects_manager.fallback_activated.connect(_on_fallback_activated)
	
	add_child(effects_manager)

func _cleanup_test_environment():
	# Disconnect signals
	if effects_manager:
		if effects_manager.transition_completed.is_connected(_on_transition_completed):
			effects_manager.transition_completed.disconnect(_on_transition_completed)
		if effects_manager.fallback_activated.is_connected(_on_fallback_activated):
			effects_manager.fallback_activated.disconnect(_on_fallback_activated)
	
	# Free resources
	if effects_manager:
		effects_manager.queue_free()
	
	effects_manager = null
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

# Test fog effect
func test_fog_effect() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Configure theme for fog effect
	test_theme.enable_effects = true
	test_theme.effect_type = effects_manager.EFFECT_FOG
	
	# Apply theme
	effects_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Check that fog effect was created
	var has_fog_effect = false
	for child in effects_manager.get_children():
		if child is ColorRect and child.name == "FogEffect":
			has_fog_effect = true
			break
	
	success = assert_true(has_fog_effect, "Fog effect should be created") and success
	
	return success

# Test particle effect
func test_particle_effect() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Configure theme for particle effect
	test_theme.enable_effects = true
	test_theme.effect_type = effects_manager.EFFECT_PARTICLES
	
	# Apply theme
	effects_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Check that particle effect was created
	var has_particle_effect = false
	for child in effects_manager.get_children():
		if child is GPUParticles2D and child.name == "ParticleEffect":
			has_particle_effect = true
			break
	
	success = assert_true(has_particle_effect, "Particle effect should be created") and success
	
	return success

# Test overlay effect
func test_overlay_effect() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Configure theme for overlay effect
	test_theme.enable_effects = true
	test_theme.effect_type = effects_manager.EFFECT_OVERLAY
	
	# Apply theme
	effects_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Check that overlay effect was created
	var has_overlay_effect = false
	for child in effects_manager.get_children():
		if child is ColorRect and child.name == "OverlayEffect":
			has_overlay_effect = true
			break
	
	success = assert_true(has_overlay_effect, "Overlay effect should be created") and success
	
	return success

# Test disabled effects
func test_disabled_effects() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Configure theme with disabled effects
	test_theme.enable_effects = false
	test_theme.effect_type = effects_manager.EFFECT_FOG
	
	# Apply theme
	effects_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Check that no effects were created
	success = assert_eq(effects_manager.get_child_count(), 0, "No effects should be created when disabled") and success
	
	return success

# Test unknown effect type
func test_unknown_effect_type() -> bool:
	var success = true
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Configure theme with unknown effect type
	test_theme.enable_effects = true
	test_theme.effect_type = "unknown_effect_type"
	
	# Apply theme
	effects_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that fallback_activated signal was emitted
	success = assert_true(fallback_activated_received, "fallback_activated signal should be emitted") and success
	success = assert_true(fallback_reason.length() > 0, "Fallback reason should be provided") and success
	
	# Check that transition_completed signal was also emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	return success

# Test transition out effects
func test_transition_out_effects() -> bool:
	var success = true
	
	# First create an effect
	test_theme.enable_effects = true
	test_theme.effect_type = effects_manager.EFFECT_FOG
	effects_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow first effect to complete
	
	# Reset signal tracking
	_reset_signal_tracking()
	
	# Now apply a different effect to trigger transition
	test_theme.effect_type = effects_manager.EFFECT_OVERLAY
	effects_manager.apply_theme(test_theme)
	await get_tree().process_frame # Allow transition tween to complete
	
	# Check that transition_completed signal was emitted
	success = assert_true(transition_completed_received, "transition_completed signal should be emitted") and success
	
	# Check that old effect was removed and new one created
	var has_fog_effect = false
	var has_overlay_effect = false
	
	for child in effects_manager.get_children():
		if child is ColorRect:
			if child.name == "FogEffect":
				has_fog_effect = true
			elif child.name == "OverlayEffect":
				has_overlay_effect = true
	
	success = assert_false(has_fog_effect, "Old fog effect should be removed") and success
	success = assert_true(has_overlay_effect, "New overlay effect should be created") and success
	
	return success
