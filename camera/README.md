# Camera System Overview

This system manages the game's main camera (`Camera2D`) and its behavior.

## Core Components

-   **`CameraSystem.gd`**: The main node (`Node2D`) that orchestrates the camera logic. It initializes subsystems and calls their `update` methods. Currently, it updates in `_physics_process` to ensure synchronization with player movement.
-   **`Camera2D` (Child Node)**: The actual Godot `Camera2D` node used for rendering.
-   **`CameraConfig.gd`**: A `Resource` defining configuration parameters like smoothing speeds and follow thresholds. Found in `camera/resources/configs/`.

## Subsystems

### `FollowSystem.gd` (`camera/subsystems/follow/`)

This subsystem is responsible for making the camera follow the player character (`_target`).

**Key Logic:**

1.  **Target Assignment**: Receives the player node via `set_target` when the player spawns.
2.  **Manual Smoothing**: Implements custom smoothing logic within its `update` method (called by `CameraSystem` during `_physics_process`).
    -   The `Camera2D`'s built-in `position_smoothing_enabled` is **disabled** to avoid conflicts.
3.  **Horizontal Following**: The camera's target X position directly uses the player's `global_position.x`.
4.  **Vertical Following & Locking**:
    -   Calculates an `ideal_target_y` based on whether the player is above a certain height threshold (`follow_height_threshold`). If above, the ideal Y is the player's Y. If below, the ideal Y is a locked position calculated using `ground_viewport_ratio`.
    -   **Vertical Smoothing**: A separate variable `_smoothed_target_y` is maintained. This variable is smoothly interpolated (`lerpf`) towards the `ideal_target_y` using `vertical_smoothing_speed` from the config. This prevents abrupt jumps when the vertical lock engages or disengages.
    -   **Final Target**: The final target position for the camera uses the player's X and the `_smoothed_target_y`.
5.  **Camera Smoothing**: The camera's actual `position` is smoothly interpolated (`lerp`) towards the `final_target_position` using the general `smoothing_speed` from the config.

This two-layer smoothing approach (smoothing the target Y transition *and* smoothing the camera's movement towards that target) was implemented to resolve issues with camera snapping during vertical lock transitions and flickering caused by conflicts with built-in smoothing mechanisms.

## Debug Tools (`camera/debug/`)

Contains tools like `CameraDebugTools.gd` for toggling camera freezing during development (see `camera/debug/README.md`).
