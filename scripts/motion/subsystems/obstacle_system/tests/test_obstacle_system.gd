# scripts/motion/subsystems/obstacle_system/tests/test_obstacle_system.gd
# Test script for the ObstacleSystem.
extends Node2D

# References to nodes in the scene
@onready var player = $Player
@onready var rock_obstacle = $RockObstacle
@onready var debug_label = $DebugLabel

# Systems
var obstacle_system: ObstacleSystem
var physics_config = null

# Test state
var test_velocity = Vector2(300, 200)
var test_entity_id = 1
var test_results = []

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Initialize the obstacle system
	obstacle_system = ObstacleSystem.new()
	obstacle_system.set_debug_enabled(true)
	
	# Load physics config if available
	if ResourceLoader.exists("res://resources/physics/default_physics.tres"):
		physics_config = load("res://resources/physics/default_physics.tres")
		obstacle_system.set_physics_config(physics_config)
	
	# Connect signals
	obstacle_system.obstacle_hit.connect(_on_obstacle_hit)
	
	# Run tests after a short delay to ensure everything is initialized
	get_tree().create_timer(0.5).timeout.connect(_run_tests)

# Run the obstacle system tests
func _run_tests() -> void:
	_log_test("Starting ObstacleSystem tests...")
	
	# Basic tests
	_test_weakener_effect()
	_test_deflector_effect()
	_test_rock_obstacle()
	
	# Edge case tests
	_test_zero_velocity()
	
	# Negative tests
	_test_invalid_obstacle_type()
	
	# Display test results
	_display_test_results()

# Test the Weakener effect
func _test_weakener_effect() -> void:
	_log_test("Testing Weakener effect...")
	
	# Create a test collision context
	var collision_data = {
		"entity_id": test_entity_id,
		"velocity": test_velocity,
		"position": player.global_position,
		"normal": Vector2(0, -1),  # Hit from below
		"is_airborne": true,
		"is_sliding": false,
		"collider": rock_obstacle
	}
	
	# Create a context and apply only the Weakener effect
	var context = ObstacleContext.new_from_collision(collision_data)
	var weakener = Weakener.new()
	var config = rock_obstacle.get_obstacle_config()["weakener"]
	
	var result_velocity = weakener.apply_effect(context, config)
	
	# Verify the result
	var expected_x = test_velocity.x * config["velocity_multiplier"]
	var expected_y = test_velocity.y * config["velocity_multiplier"]
	var success = is_equal_approx(result_velocity.x, expected_x) and is_equal_approx(result_velocity.y, expected_y)
	
	var details = "Expected: (" + str(expected_x) + ", " + str(expected_y) + "), Got: (" + str(result_velocity.x) + ", " + str(result_velocity.y) + ")"
	_log_test_result("Weakener Test", success, details)

# Test the Deflector effect
func _test_deflector_effect() -> void:
	_log_test("Testing Deflector effect...")
	
	# Create a test collision context
	var collision_data = {
		"entity_id": test_entity_id,
		"velocity": test_velocity,
		"position": player.global_position,
		"normal": Vector2(0, -1),  # Hit from below
		"is_airborne": true,
		"is_sliding": false,
		"collider": rock_obstacle
	}
	
	# Create a context and apply only the Deflector effect
	var context = ObstacleContext.new_from_collision(collision_data)
	var deflector = Deflector.new()
	var config = rock_obstacle.get_obstacle_config()["deflector"]
	
	# Override angle variance for deterministic testing
	config["angle_variance"] = 0.0
	
	var result_velocity = deflector.apply_effect(context, config)
	
	# Verify the result - we can't check exact values due to trigonometry,
	# but we can check that the magnitude is preserved and the angle changed
	var original_magnitude = test_velocity.length()
	var result_magnitude = result_velocity.length()
	var original_angle = rad_to_deg(test_velocity.angle())
	var result_angle = rad_to_deg(result_velocity.angle())
	var angle_diff = abs(result_angle - original_angle)
	
	var success = is_equal_approx_with_tolerance(original_magnitude, result_magnitude, 0.1)
	success = success and is_equal_approx_with_tolerance(angle_diff, abs(config["deflect_angle"]), 0.1)
	
	var details = "Original angle: " + str(original_angle) + ", Result angle: " + str(result_angle) + ", Diff: " + str(angle_diff) + " (expected: " + str(abs(config["deflect_angle"])) + ")"
	_log_test_result("Deflector Test", success, details)

# Test the RockObstacle (combined Weakener + Deflector)
func _test_rock_obstacle() -> void:
	_log_test("Testing RockObstacle (combined effects)...")
	
	# Create a test collision context
	var collision_data = {
		"entity_id": test_entity_id,
		"velocity": test_velocity,
		"position": player.global_position,
		"normal": Vector2(0, -1),  # Hit from below
		"is_airborne": true,
		"is_sliding": false,
		"collider": rock_obstacle
	}
	
	# Process the obstacle collision
	var outcome = obstacle_system.process_obstacle_collision(test_entity_id, rock_obstacle, collision_data)
	
	# Verify the outcome
	var success = true
	if outcome.outcome_type != ObstacleOutcome.OutcomeType.MODIFIED:
		success = false
	if outcome.applied_effects.size() != 2:
		success = false
	if not outcome.applied_effects.has("weakener"):
		success = false
	if not outcome.applied_effects.has("deflector"):
		success = false
	
	var details = "Applied effects: " + str(outcome.applied_effects) + ", Outcome type: " + str(outcome.outcome_type)
	_log_test_result("RockObstacle Test", success, details)
	
	# Log the debug data
	_log_test(outcome.debug_data.get_debug_string())

# Log a test message
func _log_test(message: String) -> void:
	print(message)
	test_results.append(message)

# Log a test result
func _log_test_result(test_name: String, success: bool, details: String) -> void:
	var result = test_name + ": " + ("PASS" if success else "FAIL") + " - " + details
	print(result)
	test_results.append(result)

# Display test results in the UI
func _display_test_results() -> void:
	var result_text = ""
	for i in range(test_results.size()):
		if i > 0:
			result_text += "\n"
		result_text += test_results[i]
	debug_label.text = result_text

# Test with zero velocity
func _test_zero_velocity() -> void:
	_log_test("Testing zero velocity handling...")
	
	# Create a test collision context with zero velocity
	var collision_data = {
		"entity_id": test_entity_id,
		"velocity": Vector2.ZERO,
		"position": player.global_position,
		"normal": Vector2(0, -1),
		"is_airborne": true,
		"is_sliding": false,
		"collider": rock_obstacle
	}
	
	# Process the obstacle collision
	var outcome = obstacle_system.process_obstacle_collision(test_entity_id, rock_obstacle, collision_data)
	
	# Verify the outcome - should still be zero
	var success = outcome.resulting_velocity.is_zero_approx()
	
	var details = "Expected zero velocity, got: " + str(outcome.resulting_velocity)
	_log_test_result("Zero Velocity Test", success, details)

# Test invalid obstacle type
func _test_invalid_obstacle_type() -> void:
	_log_test("Testing invalid obstacle type handling...")
	
	# Try to get a non-existent obstacle type
	var invalid_type = "non_existent_type"
	var has_type = obstacle_system._obstacle_type_registry.has_obstacle_type(invalid_type)
	
	var status = "correctly rejected" if !has_type else "incorrectly accepted"
	var details = "System " + status + " the invalid obstacle type '" + invalid_type + "'"
	_log_test_result("Invalid Obstacle Type Test", !has_type, details)

# Signal handler for obstacle_hit
func _on_obstacle_hit(entity_id: int, obstacle_name: String, resulting_velocity: Vector2) -> void:
	var message = "Obstacle hit signal received: Entity " + str(entity_id) + " hit " + obstacle_name + ", resulting velocity: " + str(resulting_velocity)
	_log_test(message)

# Helper function to check if two floats are approximately equal with a custom tolerance
func is_equal_approx_with_tolerance(a: float, b: float, tolerance: float = 0.001) -> bool:
	return abs(a - b) < tolerance
