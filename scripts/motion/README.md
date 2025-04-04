# Motion System

A unified, modular system for managing all motion-related influences in a 2D game.

## Directory Structure

The Motion System is organized into the following components:

### Core Components
- `MotionSystem.gd`: The main coordinator that manages subsystems and resolves motion
- `MotionResolver.gd`: Handles the resolution of motion modifiers based on priority and type
- `MotionModifier.gd`: Data class representing a single motion influence

### Subsystems
- `subsystems/BounceSystem.gd`: Handles bounce physics and calculations
- `subsystems/CollisionMaterialSystem.gd`: Provides surface-based bounce and friction adjustments
- `subsystems/EnvironmentalForceSystem.gd`: Controls wind zones, gravity shifts, and turbulence
- `subsystems/EquipmentSystem.gd`: Provides gear-based passive modifiers to motion and bounce
- `subsystems/ObstacleSystem.gd`: Manages collision-based motion penalties or interruptions
- `subsystems/StatusEffectSystem.gd`: Handles timed or conditional buffs/debuffs that affect motion
- `subsystems/TraitSystem.gd`: Manages character-specific always-on motion modifiers

### Interfaces
- `interfaces/IMotionSubsystem.gd`: Interface that all subsystems must implement

### Scene Files
- `MotionSystemNode.tscn`: Scene file for the MotionSystem node
- `MotionSystemDebug.tscn`: Debug scene for the Motion System

### Documentation
- `README.md`: This file - overview of the Motion System
- `INTEGRATION.md`: Guide for integrating the Motion System with existing code
- `REFACTORING_PLAN.md`: Plan for refactoring the Motion System
- `docs_README.md`: Detailed documentation of the Motion System

### Debug Tools
- `debug_motion_system.gd`: Debug script for the Motion System
- `material_test.gd`: Test script for material properties
- `MaterialTest.tscn`: Test scene for material properties

### Examples and Tests
- `examples/`: Example scripts for using the Motion System
- `tests/`: Test scripts for the Motion System

## Usage

See the `docs_README.md` file for detailed usage instructions.
