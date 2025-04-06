#!/usr/bin/env -S godot --script
extends SceneTree

# This script tests the ModularBounceSystem to ensure it works correctly
# Run with: godot --script scripts/motion/subsystems/bounce_system/test_bounce_system.gd

func _init():
    print("Testing ModularBounceSystem...")
    
    # Create a mock MotionSystem for testing
    var mock_motion_system = MockMotionSystem.new()
    
    # Create the ModularBounceSystem
    var bounce_system = load("res://scripts/motion/subsystems/bounce_system/BounceSystem.gd").new()
    
    # Set the motion system reference
    bounce_system._motion_system = mock_motion_system
    bounce_system.on_register()
    
    # Register an entity
    var entity_id = 1
    var position = Vector2(100, 100)
    var success = bounce_system.register_entity(entity_id, position)
    print("Entity registration success: ", success)
    
    # Simulate a launch event
    var launch_velocity = Vector2(500, -800)
    bounce_system.record_launch(entity_id, launch_velocity, position)
    print("Launch recorded")
    
    # Update max height
    var max_height_position = Vector2(200, 50)
    bounce_system.update_max_height(entity_id, max_height_position)
    print("Max height updated")
    
    # Simulate a floor collision
    var collision_info = {
        "entity_id": entity_id,
        "position": Vector2(300, 100),
        "normal": Vector2(0, -1),
        "entity_type": "default",
        "mass": 1.0
    }
    
    var modifiers = bounce_system.get_collision_modifiers(collision_info)
    print("Collision modifiers count: ", modifiers.size())
    
    if modifiers.size() > 0:
        var bounce_vector = modifiers[0].vector
        print("Bounce vector: ", bounce_vector)
        
        # Check if the entity should stop bouncing
        var should_stop = bounce_system.should_stop_bouncing(entity_id)
        print("Should stop bouncing: ", should_stop)
        
        # Get bounce count
        var bounce_count = bounce_system.get_bounce_count(entity_id)
        print("Bounce count: ", bounce_count)
    
    print("Test completed successfully!")
    quit()

# Mock MotionSystem for testing
class MockMotionSystem:
    func get_physics_config():
        return MockPhysicsConfig.new()

# Mock PhysicsConfig for testing
class MockPhysicsConfig:
    var first_bounce_ratio = 0.8
    var subsequent_bounce_ratio = 0.7
    var min_bounce_threshold = 10.0
    var horizontal_preservation = 0.9
    var gravity = 1200.0
    
    func get_gravity_for_entity(_entity_type, _entity_mass):
        return gravity
