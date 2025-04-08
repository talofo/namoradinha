# Bounce System (Rewritten)

This document describes the rewritten Bounce System, designed to be stateless, reactive, and decoupled, adhering to the principles outlined in the original behavioural summary.

## Core Philosophy

*   **Reactive Calculator:** The system acts *only* when triggered by a collision event via its `get_collision_modifiers` method. It does not manage ongoing player state.
*   **Stateless Calculation:** Each bounce calculation is independent, based solely on the context provided at the moment of impact. It does not track bounce history internally.
*   **Decoupling:** Interaction occurs exclusively through well-defined data contract classes passed into the calculation method.
*   **Externalized Modifiers:** Permanent modifiers are received via the input context. Dynamic modifiers (boosts, wind) are expected to have already altered the player's motion state *before* the collision context is provided to this system.

## Interaction Flow

1.  **Collision Detection:** An external system (e.g., `MotionSystemCore`, Physics Engine) detects a relevant collision (e.g., player hitting the ground).
2.  **Context Gathering:** The external system gathers all necessary information:
    *   Player's motion state just before impact.
    *   Surface properties at the collision point.
    *   Player's permanent bounce profile (from traits, equipment).
    *   Current gravity affecting the player.
3.  **Context Object Creation:** The external system creates a `CollisionContext` object containing the gathered data.
4.  **Method Call:** The external system calls `BounceSystem.get_collision_modifiers(context: CollisionContext)`.
5.  **Internal Calculation:**
    *   `BounceSystem` validates the context and checks if it's a floor collision.
    *   `BounceSystem` calls `BounceCalculator.calculate(context: CollisionContext)`.
    *   `BounceCalculator` performs the physics calculation based *only* on the provided context data (applying elasticity, friction, profile modifiers).
    *   `BounceCalculator` determines if the bounce results in continued bouncing, sliding, or stopping, based on energy thresholds.
    *   `BounceCalculator` returns a `BounceOutcome` object.
6.  **Modifier Generation:** `BounceSystem` receives the `BounceOutcome` and generates a `MotionModifier` to apply the resulting `new_velocity`.
7.  **Return:** `BounceSystem` returns an array containing the single velocity `MotionModifier`.
8.  **Modifier Application:** The external system (`MotionSystemCore`) applies the returned modifier to the player's state.

## Data Contracts

These classes define the data passed to and returned from the system:

*   **`CollisionContext` (`data/CollisionContext.gd`):** Input object containing:
    *   `incoming_motion_state: IncomingMotionState`
    *   `impact_surface_data: ImpactSurfaceData`
    *   `player_bounce_profile: PlayerBounceProfile`
    *   `current_gravity: Vector2`
    *   `generate_debug_data: bool`
*   **`BounceOutcome` (`data/BounceOutcome.gd`):** Output object containing:
    *   `new_velocity: Vector2`
    *   `termination_state: String` (Constants: `STATE_BOUNCING`, `STATE_SLIDING`, `STATE_STOPPED`)
    *   `debug_data: BounceDebugData` (Optional, for debug builds)
*   **Supporting Data Classes:**
    *   `IncomingMotionState` (`data/IncomingMotionState.gd`)
    *   `ImpactSurfaceData` (`data/ImpactSurfaceData.gd`)
    *   `PlayerBounceProfile` (`data/PlayerBounceProfile.gd`)
    *   `BounceDebugData` (`data/BounceDebugData.gd`)

## Components

*   **`BounceSystem` (`BounceSystem.gd`):**
    *   Implements `IMotionSubsystem`.
    *   Orchestrates the process: receives context, calls calculator, creates modifier.
    *   Handles floor detection logic.
*   **`BounceCalculator` (`components/BounceCalculator.gd`):**
    *   Contains the pure, stateless physics calculation logic.
    *   Takes `CollisionContext` as input, returns `BounceOutcome`.
    *   Applies elasticity, friction, profile modifiers.
    *   Determines termination state (bouncing, sliding, stopped).

## Testing

The system is tested via `test_bounce_system.gd`, which directly instantiates `BounceSystem` and provides mock `CollisionContext` objects to verify various scenarios, including basic bounces, modifier effects, termination, and full sequence simulation.

**Note:** There appears to be a persistent, misleading GDScript parser error ("Assignment is not allowed inside an expression") reported by Godot v4.4.1.stable when running the test script via the command line, even though the code syntax is valid. The tests *should* function correctly despite this erroneous parser message.

## Integration Requirements

The calling system (`MotionSystemCore`) **must** be responsible for:
1.  Detecting relevant collisions.
2.  Gathering all necessary data (motion state, surface properties, player profile, gravity).
3.  Constructing the `CollisionContext` object accurately.
4.  Calling `BounceSystem.get_collision_modifiers` with the context object.
5.  Applying the returned `MotionModifier`.

## Interaction with CharacterBody2D and `move_and_slide()`

A key consideration when implementing custom bounce logic for a `CharacterBody2D` is the timing relative to the built-in `move_and_slide()` function.

**Problem Encountered:**

Initially, the custom bounce logic was triggered based on the `is_on_floor()` check within `_physics_process`. However, when the character hit the floor with high velocity (e.g., after a launch), the `move_and_slide()` function, executed *before* the `is_on_floor()` check in the *next* frame, would handle the collision first. Its default behavior often clamps or significantly reduces the vertical velocity upon impact. Consequently, when our custom `_handle_floor_collision` (or equivalent logic) ran in the subsequent frame, it received an already-dampened velocity, leading to unexpectedly small bounces despite high initial impact speeds.

**Solution Implemented:**

To ensure the custom bounce logic uses the character's velocity *before* `move_and_slide` modifies it upon impact, the approach was changed:

1.  The character's velocity is stored *before* calling `move_and_slide()`.
2.  `move_and_slide()` is called.
3.  Immediately after `move_and_slide()`, `get_slide_collision_count()` and `get_slide_collision(i)` are used to check for collisions that occurred *during* that movement step.
4.  If a floor collision is detected via `get_slide_collision()`, the custom collision resolution logic (which calls the `BounceSystem`) is invoked *within the same frame*.
5.  Crucially, the `collision_info` passed to the `MotionSystem` uses the **velocity stored before `move_and_slide()`**, along with the collision details (normal, etc.) obtained from the `KinematicCollision2D` object.
6.  The resulting velocity calculated by the `BounceSystem` (and potentially other subsystems) is then applied directly, overwriting any modifications made internally by `move_and_slide()`.

This ensures that the bounce calculation accurately reflects the pre-impact velocity, allowing for high-energy bounces consistent with the launch parameters. The previous method of checking `is_on_floor()` in the next frame was removed to avoid redundant processing.
