# Height Zones

This document explains the height zones feature for content placement in chunks.

## Overview

The height zones feature allows you to specify where content should be placed vertically in the game world. This ensures that certain types of content (like rocks) always appear on the ground, while others (like collectibles) can appear in the air.

## Height Zone Types

The system supports five different height zones:

1. **underground**: Content is placed below the ground level (y < 0)
2. **ground**: Content is placed exactly at ground level (y = 0)
3. **air**: Content is placed in the air at a medium height (y >= 30)
4. **stratospheric**: Content is placed very high in the air
5. **specified**: Content is placed at the exact y-coordinate specified in the marker

## Usage

To specify a height zone for a marker, add the `height_zone` property to the marker dictionary:

```gdscript
layout_markers = [{
  "name": "ObstacleMarker1",
  "position": Vector2(2, 25),
  "intended_category": "obstacle", 
  "tags": ["narrow"],
  "placement_mode": "stable-random",
  "height_zone": "ground"  # Options: "underground", "ground", "air", "stratospheric", "specified"
}]
```

If no height zone is specified, the default is `"specified"`, which uses the exact y-coordinate specified in the marker.

## Height Zone Configuration

The height ranges for each zone can be configured in the ContentDistribution resource:

```gdscript
height_zones = {
  "underground": {"y_min": -20.0, "y_max": -1.0},
  "ground": {"y": 0.0},
  "air": {"y_min": 30.0, "y_max": 60.0},
  "stratospheric": {"y_min": 80.0, "y_max": 120.0}
}
```

These ranges control the vertical position of content when using the corresponding height zone.

## Example Chunks

Three example chunks are provided to demonstrate the different height zones:

1. **default_chunk.tres**: Uses `"ground"` height zone for a single obstacle marker.
2. **varied_chunk.tres**: Contains two obstacle markers, one with `"ground"` and one with `"air"` height zone.
3. **random_chunk.tres**: Contains two obstacle markers, one with `"ground"` and one with `"stratospheric"` height zone.

## Implementation Details

### Fixed Height

The `"ground"` height zone uses a fixed y-coordinate:

```gdscript
if zone_config.has("y"):
    marker.position.y = zone_config.y
```

### Range-Based Height

The `"underground"`, `"air"`, and `"stratospheric"` height zones use a range of y-coordinates:

```gdscript
if zone_config.has("y_min") and zone_config.has("y_max"):
    var y_min = zone_config.y_min
    var y_max = zone_config.y_max
    
    if marker.get("placement_mode", "non-random") == "stable-random":
        # Use seeded RNG for stable randomization
        marker.position.y = seeded_rng.randf_range(y_min, y_max)
    elif marker.get("placement_mode", "non-random") == "fully-random":
        # Use regular RNG for full randomization
        marker.position.y = _rng.randf_range(y_min, y_max)
```

## Benefits

- **Visual Clarity**: Clear separation between ground objects and air objects
- **Predictable Placement**: Rocks and other ground objects always appear on the ground
- **Flexible Configuration**: Height zones can be adjusted to suit different game styles
- **Consistent Experience**: Players will have a more consistent experience with objects appearing where expected
