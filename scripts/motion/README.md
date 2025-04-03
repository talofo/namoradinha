# MotionSystem Architecture

A unified, modular system for managing all motion-related influences in a 2D game.

## Overview

The MotionSystem provides a centralized architecture for handling all aspects of motion in a game, from player-triggered boosts to environmental forces, equipment effects, and more. It maintains clear separation of concerns while providing a single entry point for resolving motion.

## Key Components

### Core Components

- **MotionSystem**: The main coordinator that manages subsystems and resolves motion.
- **MotionResolver**: Handles the resolution of motion modifiers based on priority and type.
- **MotionModifier**: Data class representing a single motion influence.

### Subsystems

- **BoostSystem**: Handles manual boosts, mega boosts, and environmental boosts.
- **ObstacleSystem**: Manages collision-based motion penalties or interruptions.
- **EquipmentSystem**: Provides gear-based passive modifiers to motion and bounce.
- **TraitSystem**: Manages character-specific always-on motion modifiers.
- **EnvironmentalForceSystem**: Controls wind zones, gravity shifts, and turbulence.
- **StatusEffectSystem**: Handles timed or conditional buffs/debuffs that affect motion.
- **CollisionMaterialSystem**: Provides surface-based bounce and friction adjustments.

## Motion Flow

1. Raw motion vector is generated (e.g., from player input)
2. `MotionSystem.resolve_motion()` is called
3. All active subsystems contribute their modifiers
4. MotionResolver applies modifiers based on priority and type
5. Final resulting motion vector is returned

## Usage

### Basic Setup

```gdscript
# Create the motion system
var motion_system = MotionSystem.new()
add_child(motion_system)

# Create and register subsystems
var boost_system = BoostSystem.new()
var obstacle_system = ObstacleSystem.new()
# ... create other subsystems

# Register subsystems with the motion system
motion_system.register_subsystem(boost_system)
motion_system.register_subsystem(obstacle_system)
# ... register other subsystems
```

### Resolving Motion

```gdscript
func _physics_process(delta):
    # Start with a base velocity (e.g., from player input)
    var velocity = Vector2(100, 0)  # Example: moving right
    
    # Resolve continuous motion using the motion system
    var motion_delta = motion_system.resolve_continuous_motion(delta)
    
    # Apply the motion delta to the velocity
    velocity += motion_delta
    
    # Move the character
    move_and_slide(velocity)

func _on_collision(collision_info):
    # Resolve collision motion using the motion system
    var collision_motion = motion_system.resolve_collision_motion(collision_info)
    
    # Apply the collision motion to the velocity
    velocity = collision_motion
```

### Interacting with Subsystems

```gdscript
# Trigger a boost
var boost_system = motion_system.get_subsystem("BoostSystem")
boost_system.trigger_boost(Vector2(1, 0), 10.0)  # Boost right with strength 10

# Apply a status effect
var status_system = motion_system.get_subsystem("StatusEffectSystem")
status_system.apply_effect("slow", 3.0, 0.5)  # 50% slow for 3 seconds
```

## Testing

The system includes a comprehensive test suite to validate its functionality:

```bash
# Run the tests
godot --headless --script scripts/motion/tests/run_motion_tests.gd
```

## Extending the System

To add a new subsystem:

1. Create a new class that implements the IMotionSubsystem interface
2. Register it with the MotionSystem

```gdscript
class MyCustomSystem:
    func get_name() -> String:
        return "MyCustomSystem"
    
    func on_register() -> void:
        print("[MyCustomSystem] Registered")
    
    func on_unregister() -> void:
        print("[MyCustomSystem] Unregistered")
    
    func get_continuous_modifiers(delta: float) -> Array:
        # Return modifiers for continuous motion
        return []
    
    func get_collision_modifiers(collision_info: Dictionary) -> Array:
        # Return modifiers for collision events
        return []

# Register the custom subsystem
var custom_system = MyCustomSystem.new()
motion_system.register_subsystem(custom_system)
```

## Design Patterns Used

- **Strategy Pattern**: For different motion calculation strategies
- **Observer Pattern**: For systems to notify when motion changes occur
- **Dependency Injection**: To provide subsystems to the main MotionSystem
- **Composite Pattern**: To treat individual and groups of modifiers uniformly
