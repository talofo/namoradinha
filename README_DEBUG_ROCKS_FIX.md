# Debug Rocks Fix

## Problem

The game was displaying too many rocks (around 15-20) when it should only be displaying around 8. This was causing the rocks to appear stacked vertically with similar X coordinates, rather than being spread out horizontally across the ground.

## Cause

The issue was caused by multiple debug scripts that were creating additional rocks for testing purposes:

1. **VisibleRocksTest.gd**: Creates a 3x3 grid of rocks (9 total) for testing visibility
2. **RockObstacleTest.gd**: Creates 1 test rock + 5 rocks in a pattern (6 total)
3. **FixRocksNotAppearing.gd**: Creates 1 test rock

These debug scripts were being loaded alongside the normal game content, resulting in too many rocks being displayed.

## Solution

The solution has two parts:

1. **Disable Debug Scripts**: A new script (`DisableDebugRocks.gd`) has been created to find and disable all debug scripts that create rocks. This script is loaded at game startup.

2. **Improve Rock Placement**: The rock placement code has been modified to:
   - Ensure rocks are always placed at ground level (Y=0)
   - Spread rocks out more widely across the X axis (-200 to 200 range)
   - Maintain a minimum distance of 100 units between rocks

## Implementation Details

### DisableDebugRocks

The `DisableDebugRocks.gd` script works by:
- Finding and removing any instances of the debug scenes
- Finding and disabling any instances of the debug scripts
- Running at game startup before any other initialization

### Rock Placement Improvements

The rock placement code has been modified in:
- `WeightedRandomStrategy.gd`: To ensure rocks are placed at ground level and with a wider X range
- `IContentDistributionStrategy.gd`: To handle both singular and plural forms of category names
- `default_distribution.tres`: To increase the minimum spacing between rocks

## Usage

The fix is automatically applied when the game starts. No manual intervention is required.

If you need to disable the fix (e.g., for debugging purposes), you can:
1. Comment out the `_disable_debug_rocks()` call in `Game.gd`
2. Or modify `DisableDebugRocks.gd` to exclude specific scripts

## Verification

You can verify the fix is working by:
1. Running the game
2. Observing that rocks are now spread out horizontally across the ground
3. Checking the console logs for messages from `DisableDebugRocks`
