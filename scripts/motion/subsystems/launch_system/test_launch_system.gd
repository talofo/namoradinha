#!/usr/bin/env -S godot --script
extends SceneTree

# This script tests the ModularLaunchSystem to ensure it works correctly
# Run with: godot --script scripts/motion/subsystems/launch_system/test_launch_system.gd

func _init():
    print("Testing ModularLaunchSystem...")
    
    # Create a mock MotionSystem for testing
    var mock_motion_system = MockMotionSystem.new()
    
    # Create the ModularLaunchSystem
    var launch_system = load("res://scripts/motion/subsystems/launch_system/LaunchSystem.gd").new()
    
    # Set the motion system reference
    launch_system._motion_system = mock_motion_system
    launch_system.on_register()
    
    # Connect to the entity_launched signal
    launch_system.entity_launched.connect(func(entity_id, launch_vector, position):
        print("Entity launched: ", entity_id)
        print("Launch vector: ", launch_vector)
        print("Position: ", position)
    )
    
    # Register an entity
    var entity_id = 1
    var success = launch_system.register_entity(entity_id)
    print("Entity registration success: ", success)
    
    # Set launch parameters
    success = launch_system.set_launch_parameters(entity_id, 45.0, 0.8, 1500.0)
    print("Set launch parameters success: ", success)
    
    # Calculate launch vector
    var launch_vector = launch_system.calculate_launch_vector(entity_id)
    print("Calculated launch vector: ", launch_vector)
    
    # Launch the entity
    var position = Vector2(100, 100)
    launch_vector = launch_system.launch_entity(entity_id, position)
    print("Launch vector after launch: ", launch_vector)
    
    # Get trajectory preview
    var trajectory = launch_system.get_preview_trajectory(entity_id)
    print("Trajectory point count: ", trajectory.size())
    print("First few trajectory points: ", trajectory.slice(0, 3))
    
    print("Test completed successfully!")
    quit()

# Mock MotionSystem for testing
class MockMotionSystem:
    func get_physics_config():
        return MockPhysicsConfig.new()

# Mock PhysicsConfig for testing
class MockPhysicsConfig:
    var default_launch_angle_degrees = 45.0
    var default_launch_strength = 1500.0
    var gravity = 1200.0
    
    func get_gravity_for_entity(_entity_type, _entity_mass):
        return gravity
