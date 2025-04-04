# MotionSystem Architecture

A unified, modular system for managing all motion-related influences in a 2D game.

## Overview

The MotionSystem provides a centralized architecture for handling all aspects of motion in a game, from player-triggered boosts to environmental forces, equipment effects, and more. It maintains clear separation of concerns while providing a single entry point for resolving motion.

## Key Components

### Core Components

- **MotionSystem**: The main coordinator that manages subsystems and resolves motion.
- **MotionResolver**: Handles the resolution of motion modifiers (both vector and scalar) based on priority and type.
- **MotionModifier**: Data class representing a single motion influence (vector or scalar).

### Subsystems

- **LaunchSystem**: Handles entity launching (setting initial parameters, calculating vectors) and trajectory prediction.
- **BounceSystem**: Handles bounce physics calculations, including energy loss per bounce and determining the transition from bouncing to sliding based on thresholds.
- **CollisionMaterialSystem**: Provides surface-specific properties like friction coefficients and bounce ratios based on the material the entity collides with.
- **BoostSystem**: Handles manual boosts, mega boosts, and environmental boosts. (Assumed functionality)
- **ObstacleSystem**: Manages collision-based motion penalties or interruptions. (Assumed functionality)
- **EquipmentSystem**: Provides gear-based passive modifiers to motion and bounce. (Assumed functionality)
- **TraitSystem**: Manages character-specific always-on motion modifiers. (Assumed functionality)
- **EnvironmentalForceSystem**: Controls wind zones, gravity shifts, and turbulence. (Assumed functionality)
- **StatusEffectSystem**: Handles timed or conditional buffs/debuffs that affect motion. (Assumed functionality)

## Motion Flow (Simplified Example - Player Character)

1.  **Player Input/AI:** Determines intended movement direction/actions (not handled by MotionSystem).
2.  **`PlayerCharacter._physics_process`:**
    *   Gathers current state (`position`, `velocity`, `is_on_floor`, `is_sliding`, `has_launched`, `delta`, `material`).
    *   Calls `MotionSystem.resolve_frame_motion(context)` if launched/sliding. This applies gravity and continuous modifiers (like wind). Updates `velocity`, `has_launched`, `is_sliding`.
    *   Calls `move_and_slide()`.
    *   If `is_on_floor()` after `move_and_slide()`:
        *   Calls `_handle_floor_collision()`.
3.  **`PlayerCharacter._handle_floor_collision`:**
    *   Gathers collision context (`position`, `velocity`, `normal`, state flags, `material`).
    *   Calls `MotionSystem.resolve_collision(collision_info)`.
4.  **`MotionSystem.resolve_collision`:**
    *   Determines if it's a bounce or slide scenario based on state (`has_launched`, `is_sliding`).
    *   **If Bouncing:** Calls `resolve_collision_motion()` which collects modifiers (primarily from `BounceSystem`) and resolves them via `MotionResolver` to get the bounce velocity. Updates state (`velocity`, `has_launched`, `is_sliding`) based on whether the bounce continues or transitions to sliding.
    *   **If Sliding:** Calculates deceleration based on effective friction (base friction from `CollisionMaterialSystem` or config, potentially modified by future subsystems) and gravity. Applies deceleration to velocity. Checks against `stop_threshold` and updates state (`velocity`, `is_sliding`).
    *   Returns the resulting state dictionary (`velocity`, `has_launched`, `is_sliding`, etc.).
5.  **`PlayerCharacter`:** Applies the state updates received from `MotionSystem.resolve_collision`.

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
func _physics_process(delta: float):
    # --- Simplified Example ---
    if not has_launched and not is_sliding: return

    var motion_context = { "entity_id": entity_id, "velocity": velocity, "delta": delta, ... } # Gather context
    
    # Apply gravity / continuous forces
    var motion_result = motion_system.resolve_frame_motion(motion_context)
    velocity = motion_result.get("velocity", velocity)
    # Update other state flags from motion_result...

    move_and_slide()

    if is_on_floor():
        _handle_floor_collision()

func _handle_floor_collision():
    var collision_info = { "entity_id": entity_id, "velocity": velocity, "normal": get_floor_normal(), ... } # Gather context
    
    # Handle bounce / friction / stopping
    var collision_result = motion_system.resolve_collision(collision_info)
    velocity = collision_result.get("velocity", velocity)
    # Update other state flags from collision_result...
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
# Run the LaunchSystem tests (example)
godot --script scripts/motion/tests/run_launch_test.gd 
# Note: A comprehensive test runner for all subsystems might be needed.
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
