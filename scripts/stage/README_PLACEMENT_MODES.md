# Chunk Placement Modes

This document explains the different placement modes available for content markers in chunks.

## Overview

The chunk system now supports three different placement modes for content markers:

1. **non-random**: The content is placed exactly at the position specified in the marker.
2. **stable-random**: The content is placed at a randomized position, but the randomization is deterministic (same each time).
3. **fully-random**: The content is placed at a completely random position each time the game is played.

## Usage

To specify a placement mode for a marker, add the `placement_mode` property to the marker dictionary:

```gdscript
layout_markers = [{
  "name": "ObstacleMarker1",
  "position": Vector2(2, 25),
  "intended_category": "obstacle", 
  "tags": ["narrow"],
  "placement_mode": "stable-random"  # Options: "non-random", "stable-random", "fully-random"
}]
```

If no placement mode is specified, the default is `"non-random"`.

## Randomization Ranges

The randomization ranges for each content category can be configured in the ContentDistribution resource:

```gdscript
randomization_ranges = {
  "obstacles": {"x_min": -10.0, "x_max": 10.0},
  "collectibles": {"x_min": -5.0, "x_max": 5.0},
  "boosts": {"x_min": -3.0, "x_max": 3.0}
}
```

These ranges control how far from the original position the content can be placed when using `"stable-random"` or `"fully-random"` placement modes.

## Example Chunks

Three example chunks are provided to demonstrate the different placement modes:

1. **default_chunk.tres**: Uses `"stable-random"` placement mode for a single obstacle marker.
2. **varied_chunk.tres**: Contains two obstacle markers, one with `"stable-random"` and one with `"non-random"` placement mode.
3. **random_chunk.tres**: Contains two obstacle markers, both with `"fully-random"` placement mode.

## Implementation Details

### Stable Random

The `"stable-random"` placement mode uses a seeded random number generator to ensure that the randomization is deterministic. The seed is based on the chunk ID and marker name, so the same marker in the same chunk will always be placed at the same position.

```gdscript
var seeded_rng = RandomNumberGenerator.new()
var seed_value = hash(chunk_definition.chunk_id + marker.get("name", str(i)))
seeded_rng.seed = seed_value
```

### Fully Random

The `"fully-random"` placement mode uses the global random number generator, which is randomized at initialization. This means that the positions will be different each time the game is played.

```gdscript
var random_x = _rng.randf_range(x_min, x_max)
```

## Benefits

- **Predictability**: Players will experience the same layout each time they play a level when using `"non-random"` or `"stable-random"` placement modes.
- **Variety**: Different chunks can use different placement modes, and `"fully-random"` can be used for content that should be different each time.
- **Flexibility**: Designers can choose the appropriate placement mode for each marker, allowing for precise control when needed and randomization when desired.
