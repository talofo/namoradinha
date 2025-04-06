# ModularBoostSystem

A subsystem for the MotionSystem that handles boost physics calculations and management.

## Overview

The BoostSystem manages temporary or permanent velocity boosts that can be applied to entities. It tracks active boosts, calculates their combined effect, and provides modifiers to the MotionSystem to adjust entity velocity.

## Components

- **BoostSystem.gd (ModularBoostSystem)**: Main entry point that implements IMotionSubsystem
- **BoostCalculator.gd**: Handles boost physics calculations
- **BoostEntityData.gd**: Manages entity-specific boost data

## Features

- Manages multiple simultaneous boosts per entity
- Supports temporary boosts with duration or permanent boosts
- Tracks boost history for debugging or gameplay mechanics
- Calculates combined boost vectors from multiple active boosts
- Adjusts boost effectiveness based on entity properties and physics configuration
- Provides methods for manually triggering boosts

## Integration with MotionSystem

The BoostSystem implements the `IMotionSubsystem` interface and is registered with the `MotionSystem`. It primarily contributes modifiers during the `get_continuous_modifiers` phase to adjust entity velocity.

## Usage

The `MotionSystem` automatically utilizes the `BoostSystem` during continuous motion resolution. Key interactions:

1. **Registration:** Entities must be registered with the BoostSystem before they can receive boosts:
   ```gdscript
   var boost_system = motion_system.get_subsystem("BoostSystem")
   boost_system.register_entity(entity_id)
   ```

2. **Triggering Boosts:** Boosts can be triggered manually:
   ```gdscript
   # Apply a rightward boost with strength 10 for 2 seconds
   boost_system.trigger_boost(entity_id, Vector2(1, 0), 10.0, 2.0)
   
   # Apply a permanent upward boost with strength 5
   boost_system.trigger_boost(entity_id, Vector2(0, -1), 5.0, -1)
   ```

3. **Managing Boosts:** Boosts can be removed or cleared:
   ```gdscript
   # Remove a specific boost
   boost_system.remove_boost(entity_id, boost_id)
   
   # Clear all boosts for an entity
   boost_system.clear_boosts(entity_id)
   ```

4. **Querying Boosts:** Active boosts and boost history can be queried:
   ```gdscript
   # Get all active boosts for an entity
   var active_boosts = boost_system.get_active_boosts(entity_id)
   
   # Get boost history for an entity
   var boost_history = boost_system.get_boost_history(entity_id)
   ```

## Boost Data Structure

Each boost is represented as a dictionary with the following fields:

```gdscript
{
    "id": String,              # Unique identifier for the boost
    "direction": Vector2,      # Direction of the boost
    "strength": float,         # Strength of the boost
    "duration": float,         # Duration in seconds (-1 for permanent)
    "remaining_time": float,   # Remaining time in seconds
    "created_at": float,       # Unix timestamp when the boost was created
    "removed_at": float        # Unix timestamp when the boost was removed (only in history)
}
```

## Implementation Details

- Boosts are combined additively when multiple are active
- Boost effectiveness can be reduced when boosting against current movement
- Boost effectiveness can be reduced at high speeds
- Boosts can be adjusted based on entity mass and type
- Expired boosts are automatically removed and added to history
