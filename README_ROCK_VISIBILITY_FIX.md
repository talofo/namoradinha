# Rock Visibility Fix

## Problem
Rocks were being created but not properly added to the scene tree, making them invisible during gameplay.

## Solution
The issue was fixed by implementing two key architectural improvements:

1. **GameSignalBus Singleton**:
   - Converted GameSignalBus to a proper autoload singleton
   - Created a dedicated ContentParent node to ensure all content has a proper parent in the scene tree
   - Added robust error handling for content creation

2. **RockObstacle Improvements**:
   - Set z-index to 1000 in the _ready() function to ensure rocks appear above other elements
   - Improved the visual representation with a proper texture and outline
   - Ensured the sprite is properly initialized and visible

## Implementation Details

### GameSignalBus
The GameSignalBus singleton now creates a dedicated ContentParent node that serves as the parent for all game content. This ensures that all content, including rocks, has a proper parent in the scene tree.

### RockObstacle
The RockObstacle class now sets its own z-index to 1000 in its _ready() function, ensuring it appears above other elements. It also creates a proper visual representation with a texture and outline.

### ContentFactory
The ContentFactory now properly adds content to the scene tree via the GameSignalBus singleton, with fallback mechanisms to ensure content is always added to the scene.

## Removed Debug Code
The following temporary debug scripts have been removed:
- RockVisibilityFix.gd (autoload)
- GlobalRockDebugOverlay.gd (autoload)

## Best Practices Applied
- **Single Responsibility Principle**: Each component has one job
- **Clean Architecture**: Proper dependency management
- **Object-Oriented Design**: Each object is responsible for its own appearance
