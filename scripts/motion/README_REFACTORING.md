# Motion System Refactoring

## Overview

The Motion System has been refactored to improve maintainability, scalability, and adhere to the single responsibility principle. The original `MotionSystem.gd` file was getting too large and handling too many responsibilities, making it harder to maintain and extend.

## New Architecture

The refactored system follows a modular architecture with the following components:

### Core Components

1. **MotionSystem.gd**
   - Lightweight wrapper that delegates to the core components
   - Maintains the same public API for backward compatibility
   - Forwards signals from the core system

2. **MotionSystemCore.gd**
   - Central coordinator that manages subsystems
   - Handles configuration loading
   - Delegates specific tasks to specialized components

3. **PhysicsCalculator.gd**
   - Handles physics-related calculations
   - Provides utility functions for gravity, friction, etc.
   - Encapsulates physics logic

4. **MotionStateManager.gd**
   - Manages entity state (launched, sliding, etc.)
   - Handles state transitions
   - Processes frame-based motion

### Motion Resolution Components

5. **MotionProfileResolver.gd** (New)
   - Resolves base motion parameters (friction, bounce, drag, etc.) from configuration profiles (e.g., `GroundPhysicsConfig`).
   - Provides a unified source for fundamental physics properties based on context (like biome).
   - Caches resolved profiles for performance.

6. **MotionModifierResolver.gd** (Renamed from `MotionResolver.gd`)
   - Resolves dynamic `MotionModifier` objects applied by subsystems (e.g., boosts, temporary effects).
   - Applies modifiers based on priority rules.

7. **ContinuousMotionResolver.gd**
   - Handles continuous motion resolution (integrating base physics with dynamic modifiers).
   - Collects continuous modifiers from subsystems.
   - Uses `MotionModifierResolver` to combine dynamic effects.
   - (Note: Needs updates to incorporate base parameters from `MotionProfileResolver`).

8. **CollisionMotionResolver.gd**
   - Handles collision-based motion resolution.
   - Processes bounce and slide logic.
   - Manages collision response.
   - (Note: Needs updates to incorporate base parameters from `MotionProfileResolver`).

9. **MotionDebugger.gd**
   - Provides debug functionality for both profile resolution and modifier application.
   - Logs motion-related information.
   - Helps with troubleshooting.

## Subsystem Integration

Subsystems continue to work the same way as before, implementing the `IMotionSubsystem` interface. The refactored system maintains backward compatibility with existing subsystems.

## Benefits of the Refactoring

1. **Improved Maintainability**: Each component has a clear, focused responsibility
2. **Better Scalability**: New features can be added to the appropriate component
3. **Enhanced Readability**: Smaller files are easier to understand
4. **Easier Testing**: Components can be tested in isolation
5. **DRY Principles**: Common functionality is centralized
6. **Single Responsibility**: Each class has one reason to change

## Usage

The public API of `MotionSystem.gd` remains unchanged, so existing code that uses the Motion System should continue to work without modification. The refactoring is internal and should be transparent to users of the system.

## File Structure

```
scripts/
├── motion/
│   ├── MotionSystem.gd                # Main entry point (lightweight wrapper)
│   ├── MotionModifierResolver.gd      # Resolver for dynamic motion modifiers (Renamed)
│   ├── MotionModifier.gd              # Data structure for motion modifications
│   ├── core/                          # Core components
│   │   ├── MotionSystemCore.gd        # Central coordinator
│   │   ├── MotionProfileResolver.gd   # NEW: Resolves base parameters from profiles
│   │   ├── PhysicsCalculator.gd       # Physics calculations (May need updates)
│   │   ├── MotionStateManager.gd      # State management
│   │   ├── ContinuousMotionResolver.gd # Continuous motion resolution
│   │   ├── CollisionMotionResolver.gd # Collision motion resolution
│   │   └── MotionDebugger.gd          # Debug functionality
│   ├── interfaces/                    # Interfaces
│   │   └── IMotionSubsystem.gd        # Interface for subsystems
│   └── subsystems/                    # Subsystem implementations
│       ├── boost_system/              # Boost subsystem
│       │   └── BoostSystem.gd
│       ├── bounce_system/             # Bounce subsystem
│       │   └── BounceSystem.gd
│       ├── launch_system/             # Launch subsystem
│       │   └── LaunchSystem.gd
│       ├── CollisionMaterialSystem.gd # Example of a non-nested subsystem
│       └── ...                        # Other subsystems (nested or flat)
└── ...
resources/
├── motion/
│   └── profiles/                    # NEW: Motion configuration profiles
│       ├── ground/                  # Example: Ground physics profiles
│       │   ├── GroundPhysicsConfig.gd # Script defining the resource
│       │   ├── default_ground.tres    # Default ground parameters
│       │   ├── ice_ground.tres        # Ice parameters
│       │   └── ...
│       └── ...                      # Future profiles (air, traits, etc.)
└── ...
```

## Recent Improvements

1. **Automatic Subsystem Registration**: MotionSystemCore now automatically registers all subsystems from a predefined list, eliminating the need for manual registration in Game.gd.
2. **Centralized Physics Config Access**: Removed duplicate physics_config variables from subsystems, ensuring all subsystems access the physics configuration through MotionSystemCore.
3. **Standardized Error Handling**: Improved how subsystems handle missing physics configuration with consistent checks and fallback behavior. (Note: The centralized ErrorHandler mentioned previously has been removed).
4. **Reduced Code Duplication**: Eliminated redundant code for loading and accessing physics configuration.
5. **Simplified Game Initialization**: Game.gd no longer needs to manually create and register each subsystem, making it more maintainable.
6. **Improved Signal Handling**: Fixed signal connections between subsystems by:
   - Adding entity_launched signal directly to LaunchSystem
   - Implementing proper signal forwarding in MotionSystemCore
   - Ensuring BounceSystem receives launch events correctly
7. **Dynamic Subsystem Registration**: Improved subsystem registration to be more dynamic:
   - Moved subsystem registration out of MotionSystemCore._ready() to allow explicit control via Game.gd
   - Added explicit call to register_all_subsystems() in Game.initialize_motion_system()
   - Fixed timing issues with subsystem registration and availability

## Subsystem Motion Parameter Access Pattern (Updated)

With the introduction of `MotionProfileResolver`, subsystems no longer directly access a static `PhysicsConfig`. Instead, they receive the `MotionProfileResolver` instance and query it for the current motion parameters based on context (usually the player node).

1.  **Initialization:** Subsystems needing motion parameters should implement an `initialize_with_resolver(resolver: MotionProfileResolver)` method. This method will be called by `Game.gd` or `MotionSystemCore.gd` to inject the resolver instance. Store this instance in a local variable (e.g., `_motion_profile_resolver`).

2.  **Accessing Parameters:** Within methods that require motion parameters (e.g., `get_collision_modifiers`, `try_apply_boost`, `get_continuous_modifiers`), use the stored resolver to get the current profile:

```gdscript
# Ensure resolver and player context are available
# (player_node might come from method arguments or context objects)
if not _motion_profile_resolver:
    push_warning("SubsystemName: MotionProfileResolver not available.")
    # Handle fallback - perhaps use MotionProfileResolver.DEFAULTS or skip logic
    return fallback_value

if not is_instance_valid(player_node):
    push_error("SubsystemName: Invalid player_node provided.")
    # Handle fallback
    return fallback_value

# Resolve the current motion profile for the player
var motion_profile: Dictionary = _motion_profile_resolver.resolve_motion_profile(player_node)

# Access specific parameters with fallbacks if necessary
var friction = motion_profile.get("friction", MotionProfileResolver.DEFAULTS.friction)
var bounce = motion_profile.get("bounce", MotionProfileResolver.DEFAULTS.bounce)
# ... access other needed parameters

# Use the resolved parameters in the subsystem's logic
# Example: apply friction, calculate bounce force, etc.
```

This pattern ensures that subsystems always use the centrally resolved, context-aware motion parameters, incorporating ground physics, and eventually other sources like traits, equipment, and effects, as defined by the `MotionProfileResolver`.

## Future Improvements

1. **Enhanced Debugging**: The MotionDebugger could be extended with visualization tools
2. **More Specialized Components**: As the system grows, additional components could be added
3. **Performance Optimizations**: The modular architecture makes it easier to optimize specific parts
4. **Testing Framework**: Unit tests could be added for each component
5. **Dynamic Subsystem Discovery**: The system could be extended to automatically discover and register subsystems without requiring a predefined list
6. **Subsystem Dependencies**: Add support for subsystems to declare dependencies on other subsystems
