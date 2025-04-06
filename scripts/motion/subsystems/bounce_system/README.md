# ModularBounceSystem

A subsystem for the MotionSystem that handles bounce physics calculations.

## Overview

The BounceSystem calculates the resulting velocity vector when an entity collides with a surface it should bounce off (typically the floor after being launched). It manages bounce energy loss based on physics configuration and determines when an entity should stop bouncing and transition to a sliding state.

## Components

- **BounceSystem.gd (ModularBounceSystem)**: Main entry point that implements IMotionSubsystem
- **BounceCalculator.gd**: Handles bounce physics calculations
- **BounceEntityData.gd**: Manages entity-specific bounce data

## Features

- Calculates bounce velocity based on height achieved and configured bounce ratios.
- Reduces bounce energy progressively based on configured ratios (`first_bounce_ratio`, `subsequent_bounce_ratio`).
- Applies horizontal velocity preservation (`horizontal_preservation`) during bounces, based on the original launch velocity's horizontal component.
- Determines when to stop bouncing based on a minimum height threshold (`min_bounce_threshold`).
- Correctly calculates the final horizontal velocity for a smooth transition when sliding begins (using the preserved horizontal momentum).
- Tracks bounce count for debugging or potential gameplay mechanics.

## Integration with MotionSystem

The BounceSystem implements the `IMotionSubsystem` interface and is registered with the `MotionSystem`. It primarily contributes modifiers during the `resolve_collision` phase when an entity hits the floor while in the `has_launched` state.

## Usage

The `MotionSystem` automatically utilizes the `BounceSystem` during collision resolution. Key interactions:

1. **Launch:** When an entity is launched, the `BounceSystem.record_launch` method is called (via a signal connection from `LaunchSystem`) to store the initial launch velocity and reset bounce state.
2. **Collision:** When `MotionSystem.resolve_collision` is called for a launched entity hitting the floor:
   * `MotionSystem` calls `MotionSystem.resolve_collision_motion`.
   * `resolve_collision_motion` calls `BounceSystem.get_collision_modifiers`.
   * `BounceSystem.calculate_bounce_vector` determines the bounce response (either a new bounce velocity or zero vertical velocity if transitioning to slide).
   * A `MotionModifier` with the calculated bounce vector is returned.
3. **State Transition:** `MotionSystem` uses the resulting vector from the resolver (which includes the BounceSystem's modifier) to determine if the entity continues bouncing (`velocity.y < 0`) or transitions to sliding (`velocity.y == 0`).

## Signal Dependencies

The BounceSystem depends on the following signals:

```gdscript
[
    {
        "provider": "LaunchSystem",
        "signal_name": "entity_launched",
        "method": "record_launch"
    }
]
```

## Configuration

Bounce behavior is configured via the `PhysicsConfig` resource (`res://resources/physics/default_physics.tres`):

- `first_bounce_ratio`: Multiplier for the first bounce height relative to max height achieved.
- `subsequent_bounce_ratio`: Multiplier for subsequent bounce heights relative to the previous bounce's target height.
- `min_bounce_threshold`: Minimum target height required for a bounce to occur. Below this, the entity transitions to sliding.
- `horizontal_preservation`: Factor (0.0 to 1.0) determining how much horizontal velocity is kept *per bounce*, relative to the initial launch horizontal velocity.
