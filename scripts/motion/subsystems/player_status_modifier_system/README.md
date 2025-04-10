# Player Status Modifier System

A subsystem for the MotionSystem that manages temporary status modifiers affecting player attributes and behavior.

## Overview

The PlayerStatusModifierSystem handles temporary status modifiers that can be applied to the player, such as shields, invincibility, speed boosts, or slowing effects. These modifiers have a duration and can affect various player attributes or behaviors.

## Features

- Manages temporary status modifiers with durations
- Applies and removes modifiers based on their lifetime
- Provides motion modifiers that affect player movement and behavior
- Supports various modifier types (shield, invincibility, speed boost, etc.)

## Integration with MotionSystem

The PlayerStatusModifierSystem implements the `IMotionSubsystem` interface and is registered with the `MotionSystem`. It provides motion modifiers that affect the player's movement and behavior.

## Modifier Types

Status modifiers are defined as separate classes in the `scripts/player_status_modifiers/` directory. Each modifier implements the `IPlayerStatusModifier` interface.

Examples of status modifiers include:
- **ShieldModifier**: Protects the player from damage
- **InvincibilityModifier**: Makes the player invulnerable to obstacles
- **SpeedBoostModifier**: Increases player movement speed
- **SlowedModifier**: Decreases player movement speed

## Usage

1. **Define Modifiers:** Create a new modifier class in `scripts/player_status_modifiers/` that implements the `IPlayerStatusModifier` interface:
   ```gdscript
   # Example: scripts/player_status_modifiers/ShieldModifier.gd
   class_name ShieldModifier
   extends RefCounted
   
   const IPlayerStatusModifier = preload("res://scripts/motion/subsystems/player_status_modifier_system/interfaces/IPlayerStatusModifier.gd")
   const MotionModifier = preload("res://scripts/motion/MotionModifier.gd")
   
   func apply(entity_id: String, strength: float, duration: float) -> Array:
       var modifiers = []
       # Create modifiers that implement the shield effect
       return modifiers
   ```

2. **Apply Modifiers:** Use the PlayerStatusModifierSystem to apply modifiers to the player:
   ```gdscript
   var status_system = motion_system.get_subsystem("PlayerStatusModifierSystem")
   if status_system:
       status_system.apply_modifier("shield", 10.0, 1.0) # Apply shield for 10 seconds at full strength
   ```

3. **Handle Expiration:** The system automatically handles the expiration of modifiers based on their duration.

## Extending with New Modifier Types

To add a new modifier type:

1. Create a new class in `scripts/player_status_modifiers/` that implements the IPlayerStatusModifier interface
2. Implement the apply method to return appropriate MotionModifier objects
3. Apply the modifier using the PlayerStatusModifierSystem's apply_modifier method
