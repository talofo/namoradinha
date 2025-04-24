# Camera System Overview

This system manages the game's main camera (`Camera2D`) and its behavior through a modular subsystem architecture.

## Core Components

-   **`CameraSystem.gd`**: The main node (`Node2D`) that orchestrates the camera logic. It initializes subsystems and calls their `update` methods in `_physics_process` to ensure synchronization with player movement.
-   **`Camera2D` (Child Node)**: The actual Godot `Camera2D` node used for rendering.
-   **`CameraConfig.gd`**: A `Resource` defining configuration parameters for all camera subsystems. Found in `camera/resources/configs/`.
-   **`ICameraSubsystem.gd`**: Interface that all camera subsystems implement, providing a consistent API.

## Subsystems

### `FollowSystem.gd` (`camera/subsystems/follow/`)

This subsystem is responsible for making the camera follow the player character.

**Key Logic:**

1.  **Target Assignment**: Receives the player node via `set_target` when the player spawns.
2.  **Manual Smoothing**: Implements custom smoothing logic within its `update` method.
	-   The `Camera2D`'s built-in `position_smoothing_enabled` is **disabled** to avoid conflicts.
3.  **Horizontal Following**: The camera's target X position directly uses the player's `global_position.x` with optional look-ahead based on velocity.
4.  **Vertical Following & Locking**:
	-   Calculates an `ideal_target_y` based on whether the player is above a certain height threshold (`follow_height_threshold`).
	-   **Vertical Smoothing**: Uses `_smoothed_target_y` to smoothly interpolate towards the `ideal_target_y` using `vertical_smoothing_speed`.
	-   **Look-ahead & Anticipation**: Applies additional offsets based on player velocity for smoother following during fast movements.
5.  **Camera Smoothing**: The camera's position is smoothly interpolated towards the final target position.

### `ZoomSystem.gd` (`camera/subsystems/zoom/`)

This subsystem handles dynamic camera zoom based on player movement speed and supports custom zoom effects.

**Key Logic:**

1. **Speed-Based Zoom**: Adjusts the camera zoom level based on the player's horizontal speed.
2. **Configurable Thresholds**: Uses `zoom_min_speed_threshold` and `zoom_max_speed_threshold` to determine when to start/stop zooming.
3. **Smooth Transitions**: Implements smooth interpolation between zoom levels using `zoom_smoothing_speed`.
4. **Custom Zoom Effects**: Supports setting custom zoom levels for specific durations, overriding the velocity-based zoom temporarily.

### `SlowMotionSystem.gd` (`camera/subsystems/slowmo/`)

This subsystem manages time scale manipulation for dramatic slow-motion effects.

**Key Logic:**

1. **Time Scale Control**: Modifies the engine's time scale to create slow-motion effects.
2. **Duration Management**: Uses an internal timer to automatically restore normal time scale after a specified duration.
3. **Public API**: Provides methods to trigger and stop slow motion effects from anywhere in the game.
4. **Safety Features**: Ensures time scale is properly restored even if the system is destroyed while active.

## Configuration Parameters

The `CameraConfig` resource provides centralized configuration for all camera subsystems:

- **Follow System**:
  - `smoothing_speed`: General camera follow speed
  - `vertical_smoothing_speed`: Speed for vertical lock transitions
  - `ground_viewport_ratio`: How much of the screen height the 'ground' occupies
  - `follow_height_threshold`: Percentage of screen height above the locked Y before camera follows player Y
  - Look-ahead parameters for anticipating player movement

- **Zoom System**:
  - `min_zoom`/`max_zoom`: Zoom level range
  - `zoom_min_speed_threshold`/`zoom_max_speed_threshold`: Speed thresholds for zoom changes
  - `zoom_smoothing_speed`: How quickly zoom adjusts

- **Slow Motion System**:
  - `default_slowmo_factor`: Default time scale for slow motion
  - `default_slowmo_duration`: Default duration in seconds

## Debug Tools (`camera/debug/`)

Contains tools like `CameraDebugTools.gd` for toggling camera freezing during development (see `camera/debug/README.md`).

## Usage in Game

The camera system is included in `Game.tscn` and initialized in `Game.gd`. The system automatically connects to the `player_spawned` signal to set the player as the target for all relevant subsystems.

## Dynamic Effects API

The camera system provides APIs for triggering context-specific effects:

### Slow Motion

```gdscript
# Trigger slow motion with default parameters from config
camera_system.trigger_slow_motion()

# Trigger slow motion with custom parameters (duration in seconds, time scale factor)
camera_system.trigger_slow_motion(1.5, 0.3)  # 1.5 seconds at 30% speed

# Stop slow motion manually (before duration ends)
camera_system.stop_slow_motion()

# Check if slow motion is active
var is_active = camera_system.is_slow_motion_active()
```

### Custom Zoom

```gdscript
# Set custom zoom level for a specific duration
camera_system.set_custom_zoom(1.5, 2.0)  # Zoom level 1.5 for 2 seconds

# Clear custom zoom and return to velocity-based zooming
camera_system.clear_custom_zoom()
```

These APIs allow you to create dynamic camera effects for different gameplay situations, such as:
- Zooming in for dramatic moments or to focus on details
- Zooming out to show more of the environment during special events
- Applying slow motion during impactful collisions or special moves
