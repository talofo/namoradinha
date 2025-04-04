# LaunchSystem

A subsystem for the MotionSystem that handles entity launching and trajectory prediction.

## Overview

The LaunchSystem provides a centralized way to handle launching entities with specific angles, powers, and strengths. It also includes trajectory prediction for UI visualization.

## Features

- Entity registration and tracking
- Launch parameter management (angle, power, strength)
- Launch vector calculation
- Trajectory prediction
- Launch event signaling

## Integration with MotionSystem

The LaunchSystem is designed to be registered with the MotionSystem:

```gdscript
# Create motion system
var motion_system = MotionSystem.new()

# Create launch system
var launch_system = LaunchSystem.new()

# Register launch system with motion system
motion_system.register_subsystem(launch_system)
```

## Usage

### Entity Registration

Before using the LaunchSystem, you need to register entities:

```gdscript
var entity_id = my_entity.get_instance_id()
launch_system.register_entity(entity_id)
```

### Setting Launch Parameters

```gdscript
# Set launch parameters (angle in degrees, power from 0.0 to 1.0, optional strength)
launch_system.set_launch_parameters(entity_id, 45.0, 0.8, 1500.0)
```

### Launching an Entity

```gdscript
# Launch with current parameters
var launch_vector = launch_system.launch_entity(entity_id)

# Or launch with specific parameters
var launch_vector = launch_system.launch_entity_with_parameters(entity_id, 45.0, 0.8, 1500.0)

# Apply the launch vector to the entity
my_entity.velocity = launch_vector
```

### Trajectory Prediction

```gdscript
# Get trajectory points for UI visualization
var trajectory_points = launch_system.get_preview_trajectory(entity_id)

# Draw the trajectory
for i in range(trajectory_points.size() - 1):
    draw_line(
        trajectory_points[i] + entity_position,
        trajectory_points[i + 1] + entity_position,
        Color(1, 1, 0, 0.5),
        2
    )
```

## Testing

A test scene is provided to verify the LaunchSystem functionality:

1. Open the test scene: `scripts/motion/tests/LaunchSystemTest.tscn`
2. Run the scene in the Godot editor
3. Use the UI to adjust angle and power
4. Click "Launch" to test the launch
5. Click "Reset" to reset the test object

Alternatively, you can run the test script directly:

```bash
godot --script scripts/motion/tests/run_launch_test.gd
```

## Integration with PlayerSpawner

In future refactoring steps, the PlayerSpawner will be updated to use the LaunchSystem instead of its own launch logic. This will centralize all launch-related functionality and reduce code duplication.
