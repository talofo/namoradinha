# scripts/utils/GlobalSignals.gd
# Autoload script for globally accessible signals (Event Bus)
extends Node

# Import required classes for signal parameters
# In Godot 4.4+, classes with class_name are globally available

# StageConfig is available globally via class_name
# Adding comments to clarify signal usage and standardization

# Player signals
# Signal emitted when a player character is spawned and added to the scene tree.
# Connect to this signal if you need to react to player spawning (e.g., UI, controllers).
# This signal is emitted by PlayerSpawner when a new player is spawned.
@warning_ignore("unused_signal")
signal player_spawned(player_node: PlayerCharacter)

# Stage signals - standardized for both StageManager and StageCompositionSystem
# Signal emitted when a stage is loaded with its configuration
signal stage_loaded(config) # Can accept either StageConfig or StageCompositionConfig

# Signal emitted when a stage generation is requested
signal stage_generation_requested(config: StageCompositionConfig, game_mode: String)

# Signal emitted when stage generation fails
signal stage_generation_failed(reason: String)

# Environment signals
# Signal emitted when the biome changes
signal biome_changed(biome_id: String, old_biome_id: String)

# Signal emitted when the theme changes
signal theme_changed(theme_id: String)

# Content signals

# Signal emitted to request chunk instantiation
signal request_chunk_instantiation(chunk_definition: ChunkDefinition, position: Vector3)

# Signal emitted to request content placement
signal request_content_placement(content_category: String, content_type: String, position: Vector3)

# Flow and difficulty signals
# Signal emitted when the flow state changes
signal flow_state_updated(flow_state: FlowAndDifficultyController.FlowState)

# Gameplay signals
# Signal emitted when a story stage is completed
signal story_stage_completed(stage_id: String)

# Signal emitted when a gameplay event is triggered
signal gameplay_event_triggered(event_name: String, event_data: Dictionary)

# Analytics signals
# Signal emitted for analytics tracking
signal analytics_event(event_data: Dictionary)

# Add other global signals here as needed, for example:
# signal score_updated(new_score: int)
# signal game_over()
