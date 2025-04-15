# Rock Overlap Fix

## Problem

Rocks were overlapping instead of being spread out across the floor. According to the level design document, rocks should only be in the ground chunk, but they were appearing in other chunks as well, causing them to overlap when forced to ground level (Y=0).

## Cause

The issue was caused by three main factors:

1. **Rocks Being Created in Non-Ground Chunks**: 
   - The `varied_chunk.tres` and `random_chunk.tres` files had obstacle markers in non-ground height zones (air and stratospheric)
   - When these markers were used for rock placement, they created rocks in non-ground chunks

2. **All Rocks Forced to Ground Level**: 
   - The `ContentFactory.gd` script forces all obstacles (including rocks) to be positioned at ground level (Y=0) regardless of which chunk they were created in
   - This caused rocks from different chunks to overlap at Y=0

3. **Insufficient Position Memory and Distribution**:
   - The content distribution system wasn't tracking previously used positions
   - Rocks were being placed at the same or very similar positions, causing overlaps
   - There was no sector-based placement to ensure rocks are spread across the entire width

## Solution

The solution has four parts:

1. **Restrict Rock Placement to Ground Chunks Only**:
   - Modified `WeightedRandomStrategy.gd` to only use markers in the ground height zone when the category is "obstacles" (rocks)
   - Added a check to skip procedural placement of obstacles in non-ground chunks

2. **Change Non-Ground Obstacle Markers**:
   - Changed the intended_category of non-ground obstacle markers in `varied_chunk.tres` and `random_chunk.tres` from "obstacles" to "flying_obstacles"
   - This ensures these markers won't be used for rock placement

3. **Implement Position Memory**:
   - Added a `_used_positions` array to `WeightedRandomStrategy.gd` to track all previously used positions
   - Modified the placement code to check against this array to prevent placing rocks too close to each other
   - Store all successful placements in this array to maintain memory across different placement attempts

4. **Add Sector-Based Placement with Extreme Spacing**:
   - Implemented sector-based placement for obstacles to ensure they're spread across the entire width
   - Increased the minimum distance between rocks from 100 to 1000 units
   - Expanded the randomization range from -200/200 to -2000/2000
   - Divide the available width (-2000 to 2000) into sectors based on the target count of obstacles
   - Place each obstacle in its own sector to ensure even distribution
   - Added expanding range for retry attempts to find valid positions if the initial sector-based placement fails

## Implementation Details

### WeightedRandomStrategy.gd Changes

1. Added position memory to track used positions:
```gdscript
# Store used positions to prevent duplicates
var _used_positions = []

func distribute_content(...):
    # Clear used positions for this new distribution
    _used_positions.clear()
    # rest of the function...
```

2. Added a check in the `_find_suitable_markers` function to skip non-ground markers for obstacles:
```gdscript
# For obstacles (rocks), only use markers in the ground height zone
if category_name == "obstacles" and marker.has("height_zone") and marker["height_zone"] != "ground":
    if _debug_enabled:
        print("WeightedRandomStrategy: Skipping non-ground marker for obstacles in height zone '%s'" % marker["height_zone"])
    continue
```

3. Added a check in the procedural position generation to skip placing obstacles in non-ground chunks:
```gdscript
# For obstacles (rocks), only place them in ground chunks
if category_name == "obstacles":
    # Check if this is a ground chunk by looking at the chunk_id or checking for ground markers
    var is_ground_chunk = false
    
    # Check if the chunk ID contains "ground"
    if "ground" in chunk_definition.chunk_id.to_lower():
        is_ground_chunk = true
    else:
        # Check if the chunk has any ground markers
        for marker in chunk_definition.layout_markers:
            if marker.has("height_zone") and marker["height_zone"] == "ground":
                is_ground_chunk = true
                break
    
    if not is_ground_chunk:
        if _debug_enabled:
            print("WeightedRandomStrategy: Skipping procedural placement for obstacles in non-ground chunk '%s'" % chunk_definition.chunk_id)
        break
```

4. Implemented sector-based placement for obstacles with expanded range:
```gdscript
# Use sector-based placement for obstacles to ensure they're spread out
# Divide the available width into sectors based on target count
var total_width = 4000.0  # -2000 to 2000 = 4000 total width
var sector_width = total_width / target_count
var sector_start = -2000.0 + (i * sector_width)
var sector_end = sector_start + sector_width

if _debug_enabled:
    print("WeightedRandomStrategy: Using sector %d for obstacle: x range [%f, %f]" % [i, sector_start, sector_end])

# For first attempt, use the sector-based approach
if attempt < 5:
    # Place within the assigned sector
    x_offset = _rng.randf_range(sector_start, sector_end)
    z_offset = _rng.randf_range(0, chunk_definition.length)
else:
    # For later attempts, expand the range to find any valid position
    var range_expansion = 1.0 + (attempt - 5) * 0.2  # Expand by 20% each attempt
    x_offset = _rng.randf_range(-2000.0 * range_expansion, 2000.0 * range_expansion)
    z_offset = _rng.randf_range(0, chunk_definition.length)
```

5. Added position validation against previously used positions with increased minimum distance:
```gdscript
# Check if this position is too close to any previously used position
var too_close_to_existing = false
for used_pos in _used_positions:
    var dx = position.x - used_pos.x
    var dz = position.z - used_pos.z
    var distance = sqrt(dx*dx + dz*dz)
    if distance < 1000.0:  # Increased minimum distance between obstacles from 100 to 1000
        too_close_to_existing = true
        break

if too_close_to_existing:
    if _debug_enabled and attempt == 14:
        print("WeightedRandomStrategy: Position too close to existing position, trying again")
    continue
```

6. Store successful placements in the position memory:
```gdscript
# Validate placement
if validate_placement(position, category_name, content_type, placements, constraints):
    # Add to placements with explicit coordinate naming
    placements.append({
        "category": category_name,
        "type": content_type,
        "distance_along_chunk": position.z,
        "height": position.y,
        "width_offset": position.x
    })
    
    # Store this position to avoid duplicates
    _used_positions.append(position)
    
    placed = true
    break
```

### Chunk Definition Changes

1. Changed the intended_category of the air obstacle marker in `varied_chunk.tres`:
```gdscript
"height_zone": "air",
"intended_category": "flying_obstacles", # Changed from "obstacles"
"name": "ObstacleMarker2",
```

2. Changed the intended_category of the stratospheric obstacle marker in `random_chunk.tres`:
```gdscript
"height_zone": "stratospheric",
"intended_category": "flying_obstacles", # Changed from "obstacles"
"name": "ObstacleMarker2",
```

## Results

With these changes:
1. Rocks are only placed in ground chunks
2. Rocks are spread out horizontally with a much wider range (-2000 to 2000)
3. Rocks maintain a minimum spacing of 1000 units to prevent overlapping
4. Each rock is placed in its own sector to ensure even distribution across the width

## Verification

You can verify the fix is working by:
1. Running the game
2. Observing that rocks are now spread out horizontally across the ground
3. Checking the console logs for messages from WeightedRandomStrategy about skipping non-ground markers for obstacles
