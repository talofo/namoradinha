extends Node2D

# Test script for the BoostSystem
# This script demonstrates how to use the BoostSystem and provides a way to test it

# References to systems
var motion_system = null
var boost_system = null

# Test entity ID
var test_entity_id = 1

# Test entity properties
var entity_position = Vector2(100, 100)
var entity_velocity = Vector2.ZERO

# UI elements
var debug_label = null

func _ready():
	# Create the debug label
	debug_label = Label.new()
	debug_label.position = Vector2(10, 10)
	debug_label.size = Vector2(500, 300)
	add_child(debug_label)
	
	# Initialize the motion system
	initialize_motion_system()
	
	# Schedule test sequence
	get_tree().create_timer(1.0).timeout.connect(run_test_sequence)

func initialize_motion_system():
	# Create the motion system
	motion_system = load("res://scripts/motion/MotionSystem.gd").new()
	add_child(motion_system)
	
	# Get the boost system
	boost_system = motion_system.get_subsystem("BoostSystem")
	
	if not boost_system:
		push_error("BoostSystem not found in MotionSystem")
		return
	
	# Register the test entity
	boost_system.register_entity(test_entity_id)
	
	update_debug_info("Motion system initialized")

func run_test_sequence():
	update_debug_info("Starting test sequence")
	
	# Test 1: Apply a rightward boost
	var boost_id_1 = boost_system.trigger_boost(test_entity_id, Vector2(1, 0), 10.0, 3.0)
	update_debug_info("Applied rightward boost: " + boost_id_1)
	
	# Wait 1 second
	await get_tree().create_timer(1.0).timeout
	
	# Test 2: Apply an upward boost
	var boost_id_2 = boost_system.trigger_boost(test_entity_id, Vector2(0, -1), 5.0, 2.0)
	update_debug_info("Applied upward boost: " + boost_id_2)
	
	# Wait 1 second
	await get_tree().create_timer(1.0).timeout
	
	# Test 3: Apply a diagonal boost
	var boost_id_3 = boost_system.trigger_boost(test_entity_id, Vector2(1, -1).normalized(), 15.0, 4.0)
	update_debug_info("Applied diagonal boost: " + boost_id_3)
	
	# Wait 1 second
	await get_tree().create_timer(1.0).timeout
	
	# Test 4: Remove a boost
	boost_system.remove_boost(test_entity_id, boost_id_1)
	update_debug_info("Removed rightward boost: " + boost_id_1)
	
	# Wait 1 second
	await get_tree().create_timer(1.0).timeout
	
	# Test 5: Clear all boosts
	boost_system.clear_boosts(test_entity_id)
	update_debug_info("Cleared all boosts")
	
	# Wait 1 second
	await get_tree().create_timer(1.0).timeout
	
	# Test 6: Apply a permanent boost
	var boost_id_4 = boost_system.trigger_boost(test_entity_id, Vector2(0, 1), 3.0, -1)
	update_debug_info("Applied permanent downward boost: " + boost_id_4)
	
	# Wait 1 second
	await get_tree().create_timer(1.0).timeout
	
	# Test 7: Get boost history
	var boost_history = boost_system.get_boost_history(test_entity_id)
	update_debug_info("Boost history count: " + str(boost_history.size()))
	
	# Test complete
	update_debug_info("Test sequence complete")

func _process(delta):
	if not boost_system:
		return
	
	# Simulate motion system update
	var modifiers = boost_system.get_continuous_modifiers(delta)
	
	# Apply modifiers to entity velocity
	for modifier in modifiers:
		if modifier.type == "velocity":
			if modifier.is_additive:
				entity_velocity += modifier.vector * modifier.scalar
			else:
				entity_velocity = modifier.vector * modifier.scalar
	
	# Apply velocity to position
	entity_position += entity_velocity * delta
	
	# Update debug info
	update_debug_info("Position: " + str(entity_position) + "\nVelocity: " + str(entity_velocity))

func update_debug_info(message):
	if debug_label:
		var current_text = debug_label.text
		var lines = current_text.split("\n")
		
		# Keep only the last 10 lines
		if lines.size() > 10:
			lines = lines.slice(lines.size() - 10, lines.size())
		
		# Add the new message
		lines.append(message)
		
		# Update the label
		debug_label.text = "\n".join(lines)
		
		# Log to console as well
		print("[BoostSystemTest] " + message)
