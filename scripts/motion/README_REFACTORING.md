# Motion System Refactoring

## Overview

The Motion System has been refactored to improve maintainability, scalability, and adhere to the single responsibility principle. The original `MotionSystem.gd` file was getting too large and handling too many responsibilities, making it harder to maintain and extend.

## New Architecture

The refactored system follows a modular architecture with the following components:

### Core Components

1. **MotionSystem.gd**
   - Lightweight wrapper node that delegates to the core components.
   - Maintains the same public API for backward compatibility.
   - Forwards signals from the core system.

2. **MotionSystemCore.gd**
   - Central coordinator (RefCounted) that manages subsystems.
   - Loads the main `PhysicsConfig` resource (`default_physics.tres`).
   - Delegates specific tasks to specialized components.
   - Injects dependencies (like `PhysicsConfig` and `MotionProfileResolver`) into subsystems.

3. **PhysicsCalculator.gd**
   - Handles physics-related calculations (e.g., applying gravity, friction).
   - Encapsulates physics logic, often using parameters resolved by `MotionProfileResolver`.

4. **MotionStateManager.gd**
   - Manages entity state (launched, sliding, etc.).
   - Handles state transitions.
   - Processes frame-based motion.

### Motion Resolution Components

5. **MotionProfileResolver.gd** (New)
   - Resolves the final motion parameters (friction, bounce, drag, boost strengths, material properties, etc.) by layering different configuration sources.
   - **Sources (in order of application, lowest to highest priority):**
     - **PhysicsConfig:** Loads global physics rules and defaults (`default_physics.tres`).
     - **GroundPhysicsConfig:** Applies biome-specific overrides (e.g., `default_ground.tres`, `ice_ground.tres`).
     - **(Future):** Equipment, Traits, Status Effects.
   - Provides a unified source for fundamental physics properties based on context.
   - Caches resolved profiles for performance.

6. **MotionModifierResolver.gd** (Renamed from `MotionResolver.gd`)
   - Resolves dynamic `MotionModifier` objects applied by subsystems (e.g., boosts, temporary effects).
   - Applies modifiers based on priority rules.

7. **ContinuousMotionResolver.gd**
   - Handles continuous motion resolution (integrating base physics with dynamic modifiers).
   - Collects continuous modifiers from subsystems.
   - Uses `MotionModifierResolver` to combine dynamic effects.
   - Uses parameters from the profile resolved by `MotionProfileResolver`.

8. **CollisionMotionResolver.gd**
   - Handles collision-based motion resolution.
   - Creates `CollisionContext` and `ImpactSurfaceData` (using material properties resolved via `MotionProfileResolver` and provided by `CollisionMaterialSystem`).
   - Delegates collision handling to relevant subsystems (like `BounceSystem`).
   - Manages collision response.

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

1. **Automatic Subsystem Registration**: `MotionSystemCore` automatically registers subsystems from a predefined list.
2. **Standardized Error Handling**: Improved handling of missing configurations with consistent checks and fallbacks.
3. **Reduced Code Duplication**: Centralized configuration loading and access.
4. **Simplified Game Initialization**: `Game.gd` initialization is cleaner due to automatic registration.
5. **Improved Signal Handling**: Fixed signal connections between subsystems.
6. **Dynamic Subsystem Registration**: Registration is now controlled explicitly by `Game.gd`.
7. **PhysicsConfig Integration**: `MotionProfileResolver` now incorporates global physics parameters from `PhysicsConfig` (`default_physics.tres`) as the base layer for profile resolution.
8. **Direct Config Injection**: `MotionSystemCore` now attempts to inject the loaded `PhysicsConfig` directly into subsystems that need it (like `CollisionMaterialSystem`).

## Subsystem Motion Parameter Access Pattern (Updated)

Subsystems primarily interact with motion parameters in two ways:

1.  **Using the Resolved Motion Profile:** For most dynamic calculations (boosts, bounce logic, continuous forces), subsystems should use the `MotionProfileResolver`.
    *   **Initialization:** Implement `initialize_with_resolver(resolver: MotionProfileResolver)` and store the resolver instance.
    *   **Access:** In relevant methods, call `_motion_profile_resolver.resolve_motion_profile(player_node)` to get the fully resolved dictionary of parameters (which includes values layered from `PhysicsConfig`, `GroundPhysicsConfig`, etc.). Access parameters using `.get("param_name", fallback_value)`.

2.  **Using Directly Injected PhysicsConfig:** For subsystems that manage fundamental properties based *only* on the global config (like `CollisionMaterialSystem` setting base material properties), they can receive the `PhysicsConfig` directly.
    *   **Initialization:** Implement `set_physics_config(config: PhysicsConfig)` and store the config instance. This method is called by `MotionSystemCore` during registration.
    *   **Access:** Use the stored `_physics_config` reference (e.g., `_physics_config.default_material_bounce`).

This dual approach allows subsystems to access either the fully resolved, context-aware parameters or the base global parameters as needed.

## Future Improvements

1. **Enhanced Debugging**: The MotionDebugger could be extended with visualization tools
2. **More Specialized Components**: As the system grows, additional components could be added
3. **Performance Optimizations**: The modular architecture makes it easier to optimize specific parts
4. **Testing Framework**: Unit tests could be added for each component
5. **Dynamic Subsystem Discovery**: The system could be extended to automatically discover and register subsystems without requiring a predefined list
6. **Subsystem Dependencies**: Add support for subsystems to declare dependencies on other subsystems
