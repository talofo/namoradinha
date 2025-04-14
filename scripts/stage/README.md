# Stage Composition System

The Stage Composition System is a modular framework for procedurally generating and managing game stages with dynamic content distribution, flow control, and difficulty scaling.

## Architecture

The system is composed of several interconnected components:

1. **StageCompositionSystem**: The main facade that provides the public API for the system.
2. **StageCompositionManager**: The central coordinator that manages the subsystems and handles stage generation, player position updates, and game mode transitions.
3. **ChunkManagementSystem**: Responsible for selecting, generating, and managing chunks based on the stage configuration and player position.
4. **ContentDistributionSystem**: Handles the distribution of content (obstacles, collectibles, boosts, etc.) within chunks based on flow state and difficulty.
5. **StageConfigSystem**: Manages the loading, validation, and retrieval of stage configuration resources.
6. **FlowAndDifficultyController**: Controls the flow state and difficulty of the stage based on player position and performance metrics.
7. **StageDebugOverlay**: Provides a visual overlay for debugging the system during development.

## Resource Types

The system uses several resource types to configure its behavior:

1. **StageCompositionConfig**: Defines the overall configuration for a stage, including theme, difficulty, flow profile, and end conditions.
2. **ChunkDefinition**: Defines a chunk of the stage, including its layout markers, theme tags, and difficulty rating.
3. **ContentDistribution**: Defines the rules for distributing content within chunks, including content categories, placement constraints, and difficulty scaling.

## Usage

### Basic Usage

```gdscript
# Get a reference to the StageCompositionSystem
var stage_system = $StageCompositionSystem

# Initialize with a motion profile resolver (optional)
stage_system.initialize_with_resolver(motion_profile_resolver)

# Set the player node for tracking
stage_system.set_player_node(player)

# Generate a stage
stage_system.generate_stage("forest_stage", "story")

# Update player position (call this in _process or similar)
stage_system.update_player_position(player.global_position)

# Record a performance event
stage_system.record_performance_event(
    FlowAndDifficultyController.PerformanceMetric.PLAYER_SPEED,
    player.velocity.length()
)
```

### Game Mode Support

The system supports two game modes:

1. **Story Mode**: A linear progression with a defined end condition (distance or event).
2. **Arcade Mode**: A continuous mode with stage transitions based on the next_stage_logic in the StageCompositionConfig.

### Debug Mode

Enable debug mode to visualize the system's state:

```gdscript
stage_system.set_debug_enabled(true)
```

## Signals

The system uses the following global signals (defined in GlobalSignals.gd):

- `stage_generation_requested(config, game_mode)`: Emitted when a stage generation is requested.
- `stage_ready(config)`: Emitted when a stage is ready for gameplay.
- `stage_generation_failed(reason)`: Emitted when stage generation fails.
- `flow_state_updated(flow_state)`: Emitted when the flow state changes.
- `request_chunk_instantiation(chunk_definition, position)`: Emitted to request chunk instantiation.
- `request_content_placement(content_category, content_type, position)`: Emitted to request content placement.
- `biome_change_detected(old_biome, new_biome)`: Emitted when a biome change is detected.
- `story_stage_completed(stage_id)`: Emitted when a story stage is completed.
- `gameplay_event_triggered(event_name, event_data)`: Emitted when a gameplay event is triggered.
- `analytics_event(event_data)`: Emitted for analytics tracking.

## Integration with Other Systems

The Stage Composition System is designed to integrate with other systems in the game:

- **EnvironmentSystem**: The system can update the EnvironmentSystem with biome changes via the biome_change_detected signal.
- **MotionSystem**: The system can update the MotionSystem with ground physics changes via the MotionProfileResolver.
- **PlayerCharacter**: The system can track the player's position and performance metrics.

## Extending the System

### Adding New Content Types

To add a new content type:

1. Add it to the content_categories dictionary in a ContentDistribution resource.
2. Implement the necessary logic to handle the new content type in your game.

### Adding New Distribution Strategies

To add a new distribution strategy:

1. Create a new class that extends IContentDistributionStrategy.
2. Implement the distribute_content method.
3. Add the strategy to the ContentDistributionSystem's set_distribution_strategy method.

### Adding New Flow States

To add a new flow state:

1. Add it to the FlowState enum in FlowAndDifficultyController.
2. Update the _string_to_flow_state method to handle the new state.
3. Update the _calculate_flow_state method to use the new state.
