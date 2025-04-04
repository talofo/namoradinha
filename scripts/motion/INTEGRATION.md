# MotionSystem Integration Guide

This document explains how to integrate the MotionSystem architecture with the existing game code.

## Overview

The integration follows an incremental approach that allows you to:
1. Test the MotionSystem without breaking existing functionality
2. Toggle between the original and MotionSystem-based implementations
3. Gradually migrate features from the original to the MotionSystem

## Components

### Core Components
- **MotionSystem**: Central coordinator for motion-related systems
- **MotionResolver**: Resolves motion modifiers based on priority
- **MotionModifier**: Data class for motion influences

### Subsystems
- **BounceSystem**: Tracks bounce state and calculates bounce responses
- **StatusEffectSystem**: Tracks entity states (bouncing, sliding, etc.)
- **CollisionMaterialSystem**: Handles surface-specific motion properties
- **Other subsystems**: For equipment, traits, environmental forces, etc.

### Integration Components
- **MotionSystemPlayer**: Extended player that shadows the MotionSystem
- **Feature Flag**: Toggle in Game.gd to switch between implementations
- **Toggle Script**: Utility to switch implementations at runtime

## Setup Instructions

### Setup

The MotionSystem is now fully integrated into the game:

1. The Game scene includes the MotionSystem node
2. The PlayerSpawner uses the MotionSystemPlayer by default
3. The MotionSystemDebug node provides debugging information:
   - Press 'D' to toggle debug output
   - Press 'V' to toggle verbose logging

## Current Integration Status

### Phase 1: Non-Critical Features (Completed)
- Shadow tracking of motion through the MotionSystem
- State tracking via StatusEffectSystem
- Enhanced debugging and logging
- Toggle between implementations at runtime

### Phase 2: State Management (Implemented)
- StatusEffectSystem now tracks entity states with detailed logging
- BounceSystem tracks bounce count and calculates bounce responses
- CollisionMaterialSystem provides material-specific properties
- MotionSystemPlayer applies continuous motion modifiers from MotionSystem
- Material detection based on position (simulated for testing)

### Phase 3: Core Physics (Implemented)
- All physics calculations now use MotionSystem
- Bounce and slide physics fully implemented in MotionSystem
  - *Recent Refinements (April 2025):* Updated sliding friction to use a physics-based model (`friction * gravity * delta`) and corrected the bounce-to-slide velocity transition logic for more consistent and predictable behavior.
- State transitions managed by MotionSystem
- Material-specific physics effects (friction, bounce)

## Testing the Integration

1. Run the game
2. Press 'D' to toggle debug output
3. Press 'V' to toggle verbose logging

The console will show detailed debug output about the MotionSystem's behavior.

### Testing Different Materials

The current implementation simulates different surface materials based on the player's X position:
- **Ice** (low friction, high bounce): X < -1000
- **Mud** (high friction, low bounce): X > 1000
- **Rubber** (high friction, very high bounce): -200 < X < 200
- **Default** (medium friction, medium bounce): Everywhere else

#### Using the Material Test Tool

For easy testing of different materials, add the MaterialTest.tscn to your Game scene:
1. Open the Game scene in the Godot editor
2. Right-click on the Game node
3. Select "Instance Child Scene"
4. Choose scripts/motion/MaterialTest.tscn

This adds keyboard shortcuts for testing:
- Press **1-4** to teleport to different materials:
  - **1**: Ice (slippery, high bounce)
  - **2**: Default (medium friction, medium bounce)
  - **3**: Rubber (high friction, very high bounce)
  - **4**: Mud (very high friction, low bounce)
- Press **A/D** to change launch angle (30°, 45°, 60°)
- Press **W/S** to change launch power (0.5, 0.8, 1.0)
- Press **Space** to launch with current settings
- Press **R** to respawn at current position

The console will show detailed information about the detected material and how it affects the physics.

## Gradual Migration

The integration has progressed from shadow tracking to partial implementation:

### Phase 1 (Completed)
- Shadow tracking of MotionSystem behavior
- Logging differences for comparison

### Phase 2 (Current)
- MotionSystemPlayer now uses MotionSystem for:
  - Continuous motion modifiers (environmental forces, etc.)
  - State tracking via StatusEffectSystem
  - Bounce vector calculation via BounceSystem
  - Material properties via CollisionMaterialSystem

### Phase 3 (Completed)
- All physics calculations moved to MotionSystem
- Full material-based physics implemented
- Centralized motion resolution

### Future Enhancements
- Add environmental forces (wind, gravity zones)
- Implement equipment-based modifiers
- Add character traits that affect motion
- Create visual indicators for different materials

## Final Migration (Completed)

The MotionSystem implementation is now complete and fully integrated:

1. MotionSystemPlayer.gd uses MotionSystem for all functionality
2. Original implementation code is kept as fallback for backward compatibility
3. use_motion_system is set to true by default in Game.gd
4. PlayerSpawner always uses the MotionSystemPlayer

### Future Steps

For a complete migration, you may want to:

1. Rename MotionSystemPlayer back to CharacterPlayer
2. Remove the toggle functionality completely
3. Remove the fallback code in MotionSystemPlayer

## Troubleshooting

- **MotionSystem not found**: Ensure the MotionSystem node is added to the Game scene
- **Subsystems not registered**: Check Game._ready() for the initialize_motion_system() call
- **Missing methods warnings**: The MotionSystemPlayer now checks if methods exist before calling them
- **Material effects not working**: Make sure you're testing in the correct X position ranges
